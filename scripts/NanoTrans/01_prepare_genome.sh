#!/bin/bash
set -e -o pipefail

# 获取当前脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
source "$SCRIPT_DIR/00_config.sh"

################################################################################
# 步骤 0: 准备参考基因组 (Module 00)
################################################################################
echo ">>> [Step 0] 准备参考基因组..."
cd "$WORK_DIR/00.Reference_Genome"

# 检查文件是否存在
if [ ! -f "ref.genome.fa" ] || [ ! -f "ref.genome.gtf" ] || [ ! -f "ref.transcriptome.fa" ]; then
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

echo "Module 00 完成。"
