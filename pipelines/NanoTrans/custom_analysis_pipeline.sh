#!/bin/bash
set -e -o pipefail

################################################################################
# 用户配置区 (请根据实际情况修改以下变量)
################################################################################

# 1. 项目基础设置
# 你的 NanoTrans 安装目录 (默认当前目录)
NANOTRANS_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 你的工作/输出目录 (所有结果将生成在这里)
WORK_DIR="/mnt/TWET-20250901A/ymm/results/NanoTrans"

# 2. 数据路径设置
# 样本名称 (Batch ID)
BATCH_ID="Arabidopsis_vir1_1"
# 原始 FAST5 所在目录 (用于 PolyA 分析)
RAW_FAST5_DIR="/media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_1/fast5_multi"
# Basecalled FASTQ 所在目录 (用于比对)
BASECALLED_FASTQ_DIR="/media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/vir1_1/merge_fastq"

# 3. 参考基因组设置
# 参考基因组 FASTA 文件路径
REF_FASTA="/mnt/TWET-20250901A/ymm/data/AT_vir/reference/total_ref.fa"
# 参考基因组 GTF 文件路径
REF_GTF="/mnt/TWET-20250901A/ymm/data/AT_vir/reference/total_ref.gtf"

# 4. 样本信息表设置 (Master Sample Table)
# 如果你已经有了样本表，请设置路径；否则留空，脚本将尝试为你生成一个单样本的示例表
EXISTING_SAMPLE_TABLE=""

# 5. 实验设计 (用于差异表达分析)
# 对比组设置 (格式: 实验组,对照组)。如果是单样本，模块03将无法正常运行差异分析。
CONTRAST="treated,control" 
# 线程数
THREADS=6

################################################################################
# 初始化环境
################################################################################

echo ">>> 加载 NanoTrans 环境..."
if [ -f "$NANOTRANS_HOME/env.sh" ]; then
    source "$NANOTRANS_HOME/env.sh"
else
    echo "Error: 找不到 env.sh，请先运行 install_dependencies.sh！"
    exit 1
fi

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# 创建标准目录结构
mkdir -p 00.Reference_Genome
mkdir -p 00.Long_Reads
mkdir -p 01.Reference_Genome_based_Read_Mapping
mkdir -p 02.Isoform_Clustering_and_Quantification
mkdir -p 03.Isoform_Expression_and_Splicing_Comparison
mkdir -p 04.Isoform_RNA_Modification_Identification
mkdir -p 05.Isoform_PolyA_Tail_Length_Profiling
mkdir -p 06.Gene_Fusion_Detection
mkdir -p 07.Report

################################################################################
# 步骤 0: 准备参考基因组 (Module 00)
################################################################################
echo ">>> [Step 0] 准备参考基因组..."
cd 00.Reference_Genome

# 检查文件是否存在
if [ ! -f "ref.genome.fa" ] || [ ! -f "ref.genome.gtf" ]; then
    echo "处理参考基因组文件..."
    # 链接原始文件
    ln -sf "$REF_FASTA" ref.genome.raw.fa
    ln -sf "$REF_GTF" ref.genome.raw.gtf
    
    # 运行 NanoTrans 的预处理脚本
    perl $NANOTRANS_HOME/scripts/tidy_fasta.pl -i ref.genome.raw.fa -o ref.genome.fa
    perl $NANOTRANS_HOME/scripts/tidy_id_in_ensembl_gtf.pl -i ref.genome.raw.gtf -o ref.genome.gtf
    perl $NANOTRANS_HOME/scripts/transcript2gene_map_by_ensembl_gtf.pl -i ref.genome.gtf -o ref.transcript2gene_map.txt -ignore_version_number yes
    
    # 构建索引
    $samtools_dir/samtools faidx ref.genome.fa
    $java_dir/java -Djava.io.tmpdir=./tmp -Dpicard.useLegacyParser=false -jar $picard_dir/picard.jar CreateSequenceDictionary -R ref.genome.fa -O ref.genome.dict
    
    # 提取转录组并索引
    $gffread_dir/gffread ref.genome.gtf -g ref.genome.fa -w ref.transcriptome.fa
    $samtools_dir/samtools faidx ref.transcriptome.fa
    $java_dir/java -Djava.io.tmpdir=./tmp -Dpicard.useLegacyParser=false -jar $picard_dir/picard.jar CreateSequenceDictionary -R ref.transcriptome.fa -O ref.transcriptome.dict
    
    # 准备 JAFFAL 索引 (用于基因融合)
    perl $NANOTRANS_HOME/scripts/prepare_ref_genome_for_JAFFAL.pl -f ref.genome.fa -g ref.genome.gtf -p genome_annotation
else
    echo "参考基因组文件已存在，跳过处理。"
fi

# 变量定义
TRANSCRIPT2GENE_MAP="$WORK_DIR/00.Reference_Genome/ref.transcript2gene_map.txt"
REF_GENOME_GTF="$WORK_DIR/00.Reference_Genome/ref.genome.gtf"
REF_DIR="$WORK_DIR/00.Reference_Genome"

cd "$WORK_DIR"

################################################################################
# 步骤 0b: 准备样本表 (Master Sample Table)
################################################################################
echo ">>> [Step 0b] 准备样本表..."

SAMPLE_TABLE_FILE="$WORK_DIR/Master_Sample_Table.${BATCH_ID}.txt"

if [ -n "$EXISTING_SAMPLE_TABLE" ] && [ -f "$EXISTING_SAMPLE_TABLE" ]; then
    cp "$EXISTING_SAMPLE_TABLE" "$SAMPLE_TABLE_FILE"
    echo "使用已存在的样本表: $SAMPLE_TABLE_FILE"
else
    if [ ! -f "$SAMPLE_TABLE_FILE" ]; then
        echo "生成示例样本表..."
        # 自动搜索 FASTQ 文件生成表格 (仅作为示例，可能需要手动调整)
        echo -e "sample_id\tcomparison_group\treplicate_id\tbasecalled_fastq_file\tbasecalled_fast5_dir\tnote" > "$SAMPLE_TABLE_FILE"
        
        # 假设只有一个样本，尝试找到 fastq 文件
        FASTQ_FILE=$(find "$BASECALLED_FASTQ_DIR" -name "*.fastq.gz" | head -n 1)
        if [ -z "$FASTQ_FILE" ]; then
             FASTQ_FILE="path/to/your/sample.fastq.gz"
        fi
        
        # 写入一行示例数据
        echo -e "Sample1\ttreated\trep1\t${FASTQ_FILE}\t${RAW_FAST5_DIR}\tDemo_Sample" >> "$SAMPLE_TABLE_FILE"
        
        echo "警告: 已生成默认样本表 $SAMPLE_TABLE_FILE"
        echo "请务必检查该文件内容是否正确！(特别是 comparison_group 和 文件路径)"
        # read -p "请检查样本表后按回车继续..."
    fi
fi

################################################################################
# 步骤 1: 比对 (Module 01)
################################################################################
echo ">>> [Step 1] 运行 Module 01: Read Mapping..."
cd 01.Reference_Genome_based_Read_Mapping

perl $NANOTRANS_HOME/scripts/batch_long_read_spliced_mapping.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -ref_dir $REF_DIR \
    -batch $BATCH_ID \
    -debug no

perl $NANOTRANS_HOME/scripts/summarize_mapping_coverage.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -batch $BATCH_ID \
    -debug no

cd "$WORK_DIR"

################################################################################
# 步骤 2: 定量 (Module 02)
################################################################################
echo ">>> [Step 2] 运行 Module 02: Isoform Quantification..."
cd 02.Isoform_Clustering_and_Quantification

MAPPING_DIR="$WORK_DIR/01.Reference_Genome_based_Read_Mapping"

# 激活 flair 环境
source $miniconda3_dir/activate $build_dir/flair_conda_env

perl $NANOTRANS_HOME/scripts/batch_isoform_clustering_and_quantification.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -ref_dir $REF_DIR \
    -mapping_dir $MAPPING_DIR \
    -transcript2gene_map $TRANSCRIPT2GENE_MAP \
    -batch $BATCH_ID \
    -debug no

# 绘图
source $miniconda3_dir/activate $build_dir/r_conda_env
perl $NANOTRANS_HOME/scripts/batch_plot_isoform_usage_for_pdf.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -batch $BATCH_ID \
    -debug no
source $miniconda3_dir/deactivate

cd "$WORK_DIR"

################################################################################
# 步骤 3: 差异表达分析 (Module 03)
################################################################################
echo ">>> [Step 3] 运行 Module 03: Differential Expression..."
cd 03.Isoform_Expression_and_Splicing_Comparison

ISOFORM_CQ_DIR="$WORK_DIR/02.Isoform_Clustering_and_Quantification"
QUANT_TABLE="${ISOFORM_CQ_DIR}/${BATCH_ID}/all_samples_combined/${BATCH_ID}.all_samples_combined.counts_matrix.tidy.txt"
RAW_QUANT_TABLE="${ISOFORM_CQ_DIR}/${BATCH_ID}/all_samples_combined/${BATCH_ID}.all_samples_combined.counts_matrix.tsv"
ISOFORM_BED="${ISOFORM_CQ_DIR}/${BATCH_ID}/all_samples_combined/${BATCH_ID}.all_samples_combined.flair_all_collapsed.isoforms.bed"
DIFFSPLICE_OUTDIR="./${BATCH_ID}/all_samples_combined/${BATCH_ID}_differential_splicing_output"

# 检查样本数，如果只有1个样本，跳过差异分析
SAMPLE_COUNT=$(tail -n +2 "$SAMPLE_TABLE_FILE" | wc -l)
if [ "$SAMPLE_COUNT" -lt 2 ]; then
    echo "警告: 样本表中只有 $SAMPLE_COUNT 个样本，无法进行差异表达分析。跳过 Module 03。"
else
    # 激活 R 环境
    source $miniconda3_dir/activate $build_dir/r_conda_env
    
    # 1. 差异表达 (Gene/Isoform)
    Rscript --vanilla $NANOTRANS_HOME/scripts/differential_expression.R \
        --tidy_count_table ${QUANT_TABLE} \
        --master_table ${SAMPLE_TABLE_FILE} \
        --contrast ${CONTRAST} \
        --batch_id ${BATCH_ID}

    # 2. 差异 Usage
    Rscript --vanilla $NANOTRANS_HOME/scripts/differential_isoform_usage.R \
        --tidy_count_table ${QUANT_TABLE} \
        --master_table ${SAMPLE_TABLE_FILE} \
        --contrast ${CONTRAST} \
        --batch_id ${BATCH_ID}
    
    source $miniconda3_dir/deactivate

    # 3. 差异剪接 (需要 Python 环境)
    source $miniconda3_dir/activate $build_dir/flair_conda_env
    
    mkdir -p ${DIFFSPLICE_OUTDIR}
    call_ds_program=${build_dir}/flair_conda_env/lib/python*/site-packages/flair
    
    python ${call_ds_program}/call_diffsplice_events.py ${ISOFORM_BED} ${DIFFSPLICE_OUTDIR}/diffsplice ${RAW_QUANT_TABLE}
    python ${call_ds_program}/es_as.py ${ISOFORM_BED} > ${DIFFSPLICE_OUTDIR}/diffsplice.es.events.tsv
    python ${call_ds_program}/es_as_inc_excl_to_counts.py ${RAW_QUANT_TABLE} ${DIFFSPLICE_OUTDIR}/diffsplice.es.events.tsv > ${DIFFSPLICE_OUTDIR}/diffsplice.es.events.quant.tsv
    
    source $miniconda3_dir/deactivate
    
    # 统计差异剪接结果
    source $miniconda3_dir/activate $build_dir/r_conda_env
    Rscript --vanilla $NANOTRANS_HOME/scripts/differential_splicing.R \
        --inputs_dir ${DIFFSPLICE_OUTDIR} \
        --contrast ${CONTRAST} \
        --threads ${THREADS} \
        --batch_id ${BATCH_ID}
    source $miniconda3_dir/deactivate
fi

cd "$WORK_DIR"

################################################################################
# 步骤 4: RNA 修饰识别 (Module 04)
################################################################################
echo ">>> [Step 4] 运行 Module 04: RNA Modification..."
cd 04.Isoform_RNA_Modification_Identification

# 激活 xpore 环境
source $miniconda3_dir/activate $build_dir/xpore_conda_env

# 注意：Module 04 需要 long_reads_dir，这里假设是 raw fast5 或 fastq
# 实际上 NanoTrans 脚本这里使用的是 FASTQ 目录
perl $NANOTRANS_HOME/scripts/batch_rna_modification_detection.pl \
    -batch_id $BATCH_ID \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -long_reads_dir $BASECALLED_FASTQ_DIR \
    -isoform_cq_dir $ISOFORM_CQ_DIR \
    -transcript2gene_map $TRANSCRIPT2GENE_MAP \
    -debug no

source $miniconda3_dir/deactivate

# 绘图
source $miniconda3_dir/activate $build_dir/r_conda_env
perl $NANOTRANS_HOME/scripts/batch_plot_rna_modification_results.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -batch $BATCH_ID \
    -top_n 20 \
    -debug no
source $miniconda3_dir/deactivate

cd "$WORK_DIR"

################################################################################
# 步骤 5: PolyA 尾长分析 (Module 05)
################################################################################
echo ">>> [Step 5] 运行 Module 05: PolyA Profiling..."
cd 05.Isoform_PolyA_Tail_Length_Profiling

# 激活环境 (通常使用 nanopolish)
source $miniconda3_dir/activate $build_dir/nanopolish_conda_env

# 注意：Raw fast5 目录需要传递给脚本
# 这里的 long_reads_dir 在 Module 05 中实际上是指包含 fast5 的目录，或者是 fastq 目录但能找到 fast5
# 原始脚本参数 -long_reads_dir 指向的是 FASTQ 目录，但是 sample_table 中有 fast5 路径
perl $NANOTRANS_HOME/scripts/batch_polya_tail_length_profiling.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -long_reads_dir $BASECALLED_FASTQ_DIR \
    -isoform_cq_dir $ISOFORM_CQ_DIR \
    -mapping_dir $MAPPING_DIR \
    -method nanopolish \
    -transcript2gene_map $TRANSCRIPT2GENE_MAP \
    -batch $BATCH_ID \
    -debug no

source $miniconda3_dir/deactivate

# 绘图
source $miniconda3_dir/activate $build_dir/r_conda_env
perl $NANOTRANS_HOME/scripts/batch_plot_polya_tail_length_results.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -batch $BATCH_ID \
    -debug no
source $miniconda3_dir/deactivate

cd "$WORK_DIR"

################################################################################
# 步骤 6: 基因融合检测 (Module 06)
################################################################################
echo ">>> [Step 6] 运行 Module 06: Gene Fusion Detection..."
cd 06.Gene_Fusion_Detection

# JAFFAL 需要 java 等环境，已被 env.sh 加载
# 激活环境
source $miniconda3_dir/activate $build_dir/jaffal_conda_env

perl $NANOTRANS_HOME/scripts/batch_gene_fusion_detection.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -for_human no \
    -ref_dir $REF_DIR \
    -long_reads_dir $BASECALLED_FASTQ_DIR \
    -transcript2gene_map $TRANSCRIPT2GENE_MAP \
    -batch $BATCH_ID \
    -debug no

source $miniconda3_dir/deactivate

# 绘图
source $miniconda3_dir/activate $build_dir/r_conda_env
perl $NANOTRANS_HOME/scripts/batch_plot_gene_fusion_results.pl \
    -sample_table $SAMPLE_TABLE_FILE \
    -threads $THREADS \
    -gtf $REF_GENOME_GTF \
    -batch $BATCH_ID 
source $miniconda3_dir/deactivate

cd "$WORK_DIR"

################################################################################
# 步骤 7: 生成报告 (Module 07)
################################################################################
echo ">>> [Step 7] 生成 HTML 报告..."
cd 07.Report

# 复制报告模板
cp $NANOTRANS_HOME/Project_Template/07.Report/NanoTrans_Report.qmd .

# 激活 Quarto 环境
source $miniconda3_dir/activate $build_dir/quarto_conda_env

# 确保 R 在 PATH 中
R_DIR=$(which R)
R_DIR=${R_DIR%/*}
export PATH=${R_DIR}:$PATH
export R_LIBS=$NANOTRANS_HOME/build/R_libs

quarto render NanoTrans_Report.qmd -P "wkdir:../" -P "dataset:${BATCH_ID}" --output NanoTrans_Report_${BATCH_ID}.html

source $miniconda3_dir/deactivate

echo "==========================================================="
echo "所有分析已完成！"
echo "最终报告位置: $WORK_DIR/07.Report/NanoTrans_Report_${BATCH_ID}.html"
echo "==========================================================="
