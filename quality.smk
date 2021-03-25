import glob, sys
fastqc_input = glob.glob('data/*.fastq.gz')

fastqc_output = []
for filename in fastqc_input:
  new_filename = filename.split('.')[0] + '_fastqc.html'
  fastqc_output.append(new_filename)

for filename in fastqc_input:
  if "_R1" in filename:
    new_filename = filename.split('_R1')[0] + '_R1_val_1_fastqc.html'
    fastqc_output.append(new_filename)

for filename in fastqc_input:
  if "_R2" in filename:
    new_filename = filename.split('_R2')[0] + '_R2_val_2_fastqc.html'
    fastqc_output.append(new_filename)



rule fastqc_a_file:
  input:
    fastqc_input
  output:
    "{filename}_fastqc.html",
    "{filename}_fastqc.zip"
  conda:
    "quality.yml"
  log:
    "logs/fastqc/{filename}.log",
  shell:
    "fastqc {input}"

rule run_multiqc:
  input:
    fastqc_output
  output:
    "multiqc_report.html",
    directory("multiqc_data")
  shell:
    "multiqc data/"

rule trim_galore:
  input:
    "{filename}.fastq.gz"
  output:
    "{filename}_R1_val_1.fastq.gz",
    "{filename}_R1.fastq.gz_trimming_report.txt",
    "{filename}_R2_val_2.fastq.gz",
    "{filename}_R2.fastq.gz_trimming_report.txt"
  shell:
    "trim_galore -q 5 --paired --cores 2 {input}"




