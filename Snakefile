# rules

rule all:
  input:
    "multiqc_report.html",

# modules

include: "rules/quality.smk"
#include: "rules/mapping.smk"

