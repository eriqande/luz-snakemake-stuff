





rule mapping:
  input:
    seq_1 = input_R1,
    seq_2 = input_R2,
    genome = "genome/COYE.fa"
  output:
    bam = "results/mapped/{trim_status}/{sample}.bam"
  shell:
    "mem -t 8 {input.genome} {input.seq_1} {input.seq_2} > {output.bam}"
