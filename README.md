Working Through Luz’s Snakemake Endeavors
================
Eric C. Anderson

  - [The Setup](#the-setup)
      - [Data](#data)
      - [What we want to do with it](#what-we-want-to-do-with-it)
  - [How shall we start thinking about
    this?](#how-shall-we-start-thinking-about-this)
      - [Thinking abstractly about our input
        files](#thinking-abstractly-about-our-input-files)
      - [What should our wildcards look
        like?](#what-should-our-wildcards-look-like)
      - [Think about where to put our desired output
        files:](#think-about-where-to-put-our-desired-output-files)
          - [Outputs from mapping reads to the
            genome](#outputs-from-mapping-reads-to-the-genome)
          - [Outputs from fastqc](#outputs-from-fastqc)
          - [Outputs from trim\_galore](#outputs-from-trim_galore)
          - [Outputs from multiqc](#outputs-from-multiqc)
      - [Find the necessary inputs given the
        outputs](#find-the-necessary-inputs-given-the-outputs)

This is super cool. Luz has been working on getting her head around how
to make Snakemake useful for her project. As we’ve talked about in our
group, this is not an easy thing. But Luz has provided a perfect example
for us all to investigate so that we can start to sink our teeth into
this stuff and understand it.

# The Setup

Here is the setup for a nice minimal example to start working with:

## Data

We will imagine that we have paired-end read data from two samples in
files that we can see with the `tree` command like this:

``` sh
(base) /luz-snakemake-stuff/--% (master) tree data/
data/
├── 16N0006_S32_L001_R1.fastq.gz
├── 16N0006_S32_L001_R2.fastq.gz
├── 98N2022_S20_L001_R1.fastq.gz
└── 98N2022_S20_L001_R2.fastq.gz
```

## What we want to do with it

Here are the goals for these data:

1.  Run fastqc on all the files. (i.e. run it for each read of each
    sample)
2.  Compile the fastqc results into a multiqc report
3.  Trim the reads in each file with trim\_galore.
4.  Run fastqc on each of the trimmed files.
5.  Compile the fastqc results from the trimmed files into a multiqc
    report
6.  Map reads to to the genome. We want to map both the raw (untrimmed)
    and the trimmed reads to the genome, since we might compare the
    results from those two paths in the pipeline.

# How shall we start thinking about this?

As I am wont to do, I think it is best to start this process by just
trying to get the basic Snakemake logic down, without necessarily
getting lost in the weeds of the actual programs that get executed in
each rule. Rather, we can start by focusing on the input and output
files.

And—and this is an important point—it is often best to start thinking
about the filename and directory structure that we want for our
*outputs*, and then figure out how to get that from the inputs at our
disposal.

Of course, doing that means that we first need to think abstractly about
our input files.

## Thinking abstractly about our input files

Let’s look at that file tree again:

``` sh
(base) /luz-snakemake-stuff/--% (master) tree data/
data/
├── 16N0006_S32_L001_R1.fastq.gz
├── 16N0006_S32_L001_R2.fastq.gz
├── 98N2022_S20_L001_R1.fastq.gz
└── 98N2022_S20_L001_R2.fastq.gz
```

We see that there are constant, and also different parts of the file
names. The constant parts are `_L001_` and `.fastq.gz`. The parts that
vary are related to the samples of the samples or the names of the reads
(`R1` of `R2`).

Or, if we wanted to be different, we could say that `_L001_R` is the
constant part and 1, or 2 varies. (It turns out this will have some
advantages later…)

The other thing that we note is that things like `16N0006_S32` are sort
of hard to look at. For naming our files and things as we move through
the worklow and start creating new files, we might want to use a short,
sweet name for each sample, rather than something like `16N0006_S32`. I
suspect that the `S32` parts are unique to particular samples (i.e., the
`16N0006` part.). So in our minds we might want to think about defining
them something like this:

    sample    field_number    fq1                                    fq2
    S32       16N0006         data/16N0006_S32_L001_R1.fastq.gz      data/16N0006_S32_L001_R2.fastq.gz
    S20       98N2022         data/98N2022_S20_L001_R1.fastq.gz      data/98N2022_S20_L001_R2.fastq.gz

And thus, as we continue through our workflow, we will expect to see
filenames like `trimmed/S32-1.fq.gz` or `mapped/S32.bam`

In order to translate requested input files like `S32.1.fq.gz` into the
actual file paths for those files, I have saved a tab-delimited file
looking like the above three-row table into: `samples.tsv`.

## What should our wildcards look like?

The first thing to note is that `fastqc` seems to operate on single
FASTQ files, so it will be operating individually on files for each
*sample* and for each *read*, so those are good candidates for being
wildcards.

Now, looking ahead, we also note that in step 6, we want to map both the
trimmed and the untrimmed reads to the reference genome. So, we might
consider another wildcard, say `{read_status}`, that can help us with
that. That will become more clear as we start to, now, think backwards
from our desired output files.

## Think about where to put our desired output files:

We now start working backward from the output files we desire, and we
*think hard about which parts of their paths and names we could replace
with wildcards\!*

### Outputs from mapping reads to the genome

We could have our mapping results look something like:

    # mapping the trimmed reads
    results/mapped/trimgalore/S32.bam
    results/mapped/trimgalore/S20.bam
    
    # mapping the raw reads
    results/mapped/raw/S32.bam
    results/mapped/raw/S20.bam

In this case, `S32` and `S20` could certainly be specified by a wildcard
`{sample}`. But also, we could specify either `trimgalore` or `raw` with
another wildcard called, for example, `{trim_status}`.

Thus, any particular output of mapped reads we might produce can be
found by supplying the correct instances of wildcards to this:

    results/mapped/{trim_status}/{sample}.bam

Aha\! Cool\! Note, that if you also wanted to map reads trimmed by the
program `trimmomatic`, you could put that in the mix by just requesting
output files like

    results/mapped/trimmomatic/{sample}.bam

(so, long as you provided a rule that created the trimmomatic output in
a consistent way).

Or, if you wanted to map the raw reads, and do so in a consistent
interface, you could request:

    results/mapped/raw/{sample}.bam

### Outputs from fastqc

This is interesting here, again, because we want to do fastqc on both
the raw and the trimmed reads.

The fastqc program maybe produces two output files like an `html` file
and `zip` file. So, our outputs may look something like this:

    # from the raw reads
    results/fastqc/raw/S32.1.html
    results/fastqc/raw/S32.1_fastqc.zip
    results/fastqc/raw/S32.2.html
    results/fastqc/raw/S32.2_fastqc.zip
    
    # from the trimmed reads
    results/fastqc/trimgalore/S32.1.html
    results/fastqc/trimgalore/S32.1_fastqc.zip
    results/fastqc/trimgalore/S32.2.html
    results/fastqc/trimgalore/S32.2_fastqc.zip

Aha\! So, we could generate any possible fastqc output file by supplying
desired instances (values) to the wildcards `{read_status}`, `{sample}`,
and `{read}` to the filename patterns:

    results/fastqc/{read_status}/{sample}.{read}.html
    results/fastqc/{read_status}/{sample}.{read}_fastqc.zip

Try it out\! What values would you provide to each of those wildcards to
obtain:

    results/fastqc/trimgalore/S20.2.html
    results/fastqc/trimgalore/S20.2_fastqc.zip

### Outputs from trim\_galore

On paired-end reads, it appears that trim\_galore wants to produce
output that will look like this

    # for sample S32, read 1
    S32.1_val_1.fq.gz
    S32.1.fastq.gz_trimming_report.txt
    
    # for sample S32, read 2
    S32.2_val_1.fq.gz
    S32.2.fastq.gz_trimming_report.txt

Those carry a bit of extra junk around. Let’s strealine the fastq.gz’s

Let us plan to put all these outputs in a directory
`trimmed/trim_galore`, and, if necessary, we will move the fastq files
trim\_galore creates to have more streamlined names, such as this:

    # for sample S32, read 1
    trimmed/trim_galore/S32.1.fq.gz
    trimmed/trim_galore/S32.1.fastq.gz_trimming_report.txt
    
    # for sample S32, read 2
    trimmed/trim_galore/S32.2.fq.gz
    trimmed/trim_galore/S32.2.fastq.gz_trimming_report.txt

So, the wildcards that we have going on here are `{sample}`, and
possibly `{read}`, but because trim\_galore has a paired end setting,
the input will likely just be the `{sample}`, which will get expanded to
get the two reads.

### Outputs from multiqc

We will leave this until later as it is somewhat specific to the
program, and we have enough to work on currently.

## Find the necessary inputs given the outputs

Once we know what the desired output files of each rule are, and we can
think about them in terms of wildcards, the next step is to specify—in
each rule block—how to get the necessary inputs to create the outputs.
This is where we have to think through how it is that wildcards in the
output propagate to wildcards in the inputs.

The important thing to make sure that the logic of your Snakemake
workflow works is to ensure that the requested inputs (given
combinations of wildcards) for each rule can be found—either as the
outputs of another rule, or from an input function (for example one that
goes and finds the input fastqc files given the `{sample}` and
\`{read}).

Let’s start sketching these out starting with the rule for mapping,
making just a minimal rule (no conda/logs/params, etc. and just echoing
what the shell command would be.)

As we already saw above, we know that we want the output to be something
like: `results/mapped/{trim_status}/{sample}.bam`, so a minimal,
test-worthy rule block in our Snakefile would look like:

``` yaml
rule mapping:
  input:
    seq_1 = "results/trimmed/{trim_status}/{sample}.1.fq.gz",
    seq_2 = "results/trimmed/{trim_status}/{sample}.2.fq.gz",
    genome = "genome/COYE.fa"
  output:
    bam = "results/mapped/{trim_status}/{sample}.bam"
  shell:
    "echo bwa mem -t 8 {input.genome} {input.seq_1} {input.seq_2} > {output.bam}"
```

That rule block is, in fact, included in the Snakefile.

The important thing to note here is that if you request an output file
named `results/mapped/trim_galore/S32.bam`, then Snakemake is first
going to notice that such a file name matches the output path of the
rule `mapping` with the wildcards set like:

    trim_status: trim_galore
    sample: S32

It then (and this is the crucial part) looks to the `input` block of the
rule to figure out what input files it needs to generate
`results/mapped/trim_galore/S32.bam`. This is where it propagates the
wildcard values from the output to the input. Snakemake says, Hey, the
input files I need have *pathnames of this form*:

    seq_1 = "results/trimmed/{trim_status}/{sample}.1.fq.gz",
    seq_2 = "results/trimmed/{trim_status}/{sample}.2.fq.gz",
    genome = "genome/COYE.fa"

But to find out the actual file names it needs to produce the particular
file `results/mapped/trim_galore/S32.bam`, Snakemake is smart enough to
know that it must to substitute values in for the wildcards.  
So, it uses the values for the requested output file:

    trim_status: trim_galore
    sample: S32

Substituting those in for the wildcard patterns in the input it
determines that, to create `results/mapped/trim_galore/S32.bam`, it
needs the input files:

    seq_1 = "results/trimmed/trim_galore/S32.1.fq.gz",
    seq_2 = "results/trimmed/trim_galore/S32.2.fq.gz",
    genome = "genome/COYE.fa"

That is the fundamental of wildcard propagation from output to input
*within a rule.*

The cool thing about Snakemake is that if it finds the files:

    "results/trimmed/trim_galore/S32.1.fq.gz",
    "results/trimmed/trim_galore/S32.2.fq.gz",
    "genome/COYE.fa"

then it goes ahead and creates `results/mapped/trim_galore/S32.bam`
using the rule `mapping`.

If Snakemake does NOT find those files, then it searches through all the
other rules to see if it can match the input file paths (like
`results/trimmed/trim_galore/S32.1.fq.gz`) to the output file names of
another rule.

So, in this case, we would need to have a rule called `trim_galore`,
let’s say, that had an output file pattern that could be matched to
`results/trimmed/trim_galore/S32.1.fq.gz` and
`results/trimmed/trim_galore/S32.2.fq.gz`.

Such a rule in “bare-minimum” and “echo-testy” form would look like:

``` yaml
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
```

Notice how the files `results/trimmed/trim_galore/S32.1.fq.gz` and
`results/trimmed/trim_galore/S32.2.fq.gz`, would match the outputs

    results/trimmed/trim_galore/{sample}.1.fq.gz
    results/trimmed/trim_galore/{sample}.2.fq.gz

when the wildcard value `{sample}` was set to S32.

Aha\! This is how Snakemake is able to start from a desired output file
and then work *backwards* to identify the (possible several) different
rules that it must run in order to generate that output.
