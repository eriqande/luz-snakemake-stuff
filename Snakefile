





rule trim_galore:
  input:
    fq1 = "results/trimmed/raw/{sample}.1.fq.gz",
    fq2 = "results/trimmed/raw/{sample}.2.fq.gz"
  output:
    "results/trimmed/trim_galore/{sample}.1.fq.gz",
    "results/trimmed/trim_galore/{sample}.1.fastq.gz_trimming_report.txt",
    "results/trimmed/trim_galore/{sample}.2.fq.gz",
    "results/trimmed/trim_galore/{sample}.2.fastq.gz_trimming_report.txt"
  shell:
    "touch {output}"



rule mapping:
  input:
    seq_1 = "results/trimmed/{trim_status}/{sample}.1.fq.gz",
    seq_2 = "results/trimmed/{trim_status}/{sample}.2.fq.gz",
    genome = "genome/COYE.fa"
  output:
    bam = "results/mapped/{trim_status}/{sample}.bam"
  shell:
    "echo bwa mem -t 8 {input.genome} {input.seq_1} {input.seq_2} > {output.bam}"
