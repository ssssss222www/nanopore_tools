for fastq in /media/user/Elements_YMM/Nanopore/data/AT_202601/fastq/pass/*.fastq; do
  basename=$(basename "$fastq" .fastq)
  minimap2 -ax splice -uf -k14 -t 8 \
    /media/user/Elements_YMM/Nanopore/data/AT_202601/reference/total_ref.fa \
    "$fastq" | \
  samtools view -bS - | \
  samtools sort -@ 8 -o /media/user/Elements_YMM/Nanopore/data/AT_202601/bam/"${basename}".bam
  samtools index /media/user/Elements_YMM/Nanopore/data/AT_202601/bam/"${basename}".bam
done
