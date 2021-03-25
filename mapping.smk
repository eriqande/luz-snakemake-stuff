import glob, sys

input_R1 = glob.glob('data/*_R1.fastq.gz')
input_R2 = glob.glob('data/*_R2.fastq.gz')


rule mapping:
  input:
    seq_1 = input_R1,
    seq_2 = input_R2,
    genome = "genome/COYE.fa"
  output:
    bam = "mapping/bam/{filename}.bam"
  conda:
    "quality.yml"
  shell:
    "mem -t 8 {input.genome} {input.seq_1} {input.seq_2} > {output.bam}"
