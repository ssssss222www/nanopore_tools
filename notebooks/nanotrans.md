# Nanotrans
## output
### polya_tail
Nanopolish 原生输出的标准格式是类似 TSV/CSV 的文本文件（虽然它没有强制后缀，通常是制表符分隔）。

但是在 NanoTrans 的这个流程中，它对 Nanopolish 的原始输出做了一系列处理和重命名，所以能够看到后缀变成了 .txt 。

运行模块07之后，会看到Sample1 目录下的文件有
- Sample1.nanopolish.polya_profiling.filtered.txt （过滤后的结果，只保留了 qc_tag 为 PASS 的行，因此包含了所有质量合格的 reads 的 PolyA 长度信息）
- Sample1.nanopolish.polya_profiling.filtered.summary.txt （对过滤后的结果进行了汇总，包括每个基因的 PolyA 长度分布、平均长度、中位数等统计信息）
- Sample1.nanopolish.polya_profiling.raw.txt （原始输出，未做任何处理）

所以，虽然后缀是 .txt ，但它们的内容本质上就是制表符分隔的表格（TSV）。
