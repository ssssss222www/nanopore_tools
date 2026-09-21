# project_nanopore_tool
这个项目是开发一个集成了 nanopore 数据处理和分析的工具，包括poly(A)位点识别，polt(A)尾巴长度分析等功能。

## 功能特性
-  poly(A)位点识别
-  poly(A)尾巴长度分析
-  差异分析（如 poly(A) 尾巴长度差异分析）

## APALORD
这个项目包含了APALORD的安装和运行脚本。该工具用于比较两组样本（如 D0 和 D7）之间 APA 差异：
### Step 0: 初始化环境
加载必要的 R 包（APALORD 和 ggplot2），并创建用于存放分析结果的输出目录

### Step 1: 加载基因组注释 (GTF)
使用 load_gtf() 函数读取基因组的注释文件（示例中使用的是人类 hg38 的 21 号染色体子集）。这一步的作用是提取基因、转录本以及外显子的坐标信息，为后续多聚腺苷酸化位点（PAS）的定位提供基因组坐标参考。

### Step 2: 加载样本数据
通过 load_samples() 函数导入两组样本路径。示例中包含对照组 D0 和实验组 D7，每组各 3 个生物学重复。这定义了后续差异分析的对比矩阵。

### Step 3: 识别 PolyA 位点 (PAS Calling)
调用 PAS_calling() 函数在全转录组范围内从测序序列中识别 PolyA 位点。结果被保存为标准的 BED 格式文件，记录了所有被识别出的 PAS 的基因组坐标。

### Step 4: PAU 定量与差异分析

 4.1 PAU 定量：PAU_by_sample() 计算每个样本中各个 PAS 的使用比例（PolyA Usage, PAU）。

 4.2 差异测试：PAU_test() 基于设定的 P 值阈值（0.05），统计并筛选在两组之间存在显著差异的 PAS。

 4.3 偏好性偏移分析：end_PAS_examine() 进一步细化分析，评估多聚腺苷酸化位点在两组间是倾向于向远端（distal）延伸还是向近端（proximal）截断。

### Step 5: 全局 APA 谱分析 (APA Profiling)
使用 APA_profile() 和 APA_plot() 整合所有基因的 APA 变化趋势，评估转录组水平的整体 APA 谱改变，并输出包含显著变化基因列表的数据表以及用于宏观展示的火山图（Volcano plot）。

### Step 6: 单基因水平探索
利用 gene_explore() 函数，针对特定的候选基因（如 "GART", "ZBTB21"），提取对应的读取覆盖度与 PAS 使用情况，并绘制可视化的 PDF 图像，方便进行个案级别的验证和展示。

## NanoTrans
该项目包含了NanoTrans的安装和运行脚本。该工具集成了多种工具，用于对 nanopore 数据进行转录组分析。一共包括以下几个模块：

00.Reference_Genome参考基因组
* downloading and preprocessing the reference genome and annotation 下载和预处理参考基因组和注释

00.Long_Reads
* performing basecalling and length/quality summarization of raw Nanopore DRS fast5 reads 对 Nanopore DRS fast5 原始读取数据进行碱基识别和长度/质量总结

01.Reference_Genome_based_Read_Mapping 基于参考基因组的读取比对
* mapping the nanopore DRS reads against the reference genome 将纳米孔 DRS 读段比对到参考基因组

02.Isoform_Clustering_and_Quantification 同工型聚类和定量
* clustering and polishing isoforms and quantifying their expression levels 对异构体进行聚类和精细化分析，并量化其表达水平

03.Isoform_Expression_and_Splicing_Comparison 异构体表达和剪接比较
* comparing isoform usages and splicing preferences among different sample groups or samples 比较不同样本组或样本间的异构体使用情况和剪接偏好

04.Isoform_RNA_Modification_Identification 异构体_RNA_修饰_鉴定
* identifying RNA modification profile of each isoform 鉴定每种异构体的 RNA 修饰谱

05.Isoform_PolyA_Tail_Length_Profiling 异构体poly(A)尾巴长度分析
* profiling poly(A) tail length of each isoform 分析每种异构体的聚腺苷酸尾长度

06.Report  报告
summarizing the major results into one HTML 将主要结果汇总到一个 HTML 文件中
