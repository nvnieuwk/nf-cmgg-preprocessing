# CenterForMedicalGeneticsGhent/nf-cmgg-preprocessing

[![GitHub Actions CI Status](https://github.com/CenterForMedicalGeneticsGhent/nf-cmgg-preprocessing/workflows/nf-core%20CI/badge.svg)](https://github.com/CenterForMedicalGeneticsGhent/nf-cmgg-preprocessing/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/CenterForMedicalGeneticsGhent/nf-cmgg-preprocessing/workflows/nf-core%20linting/badge.svg)](https://github.com/CenterForMedicalGeneticsGhent/nf-cmgg-preprocessing/actions?query=workflow%3A%22nf-core+linting%22)
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.10.3-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)

## Introduction

**CenterForMedicalGeneticsGhent/nf-cmgg-preprocessing** is a bioinformatics best-practice analysis pipeline for sequencing data preprocessing at CMGG.
This workflow handles demultiplexing, alignment, qc and archiving.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!


## Pipeline summary

1. Demultiplexing
2. Alignment
3. QC
4. Coverage analysis
5. Compression

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=21.10.3`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(you can use [`Conda`](https://conda.io/miniconda.html) both to install Nextflow itself and also to manage software within pipelines. Please only use it within pipelines as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_.

3. Download the pipeline and test it on a minimal dataset with a single command:

   ```console
   nextflow run CenterForMedicalGeneticsGhent/nf-cmgg-preprocessing -profile test,YOURPROFILE --outdir <OUTDIR>
   ```

   Note that some form of configuration will be needed so that Nextflow knows how to fetch the required software. This is usually done in the form of a config profile (`YOURPROFILE` in the example command above). You can chain multiple config profiles in a comma-separated string.

   > - The pipeline comes with config profiles called `docker`, `singularity`, `podman`, `shifter`, `charliecloud` and `conda` which instruct the pipeline to use the named tool for software management. For example, `-profile test,docker`.
   > - Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
   > - If you are using `singularity`, please use the [`nf-core download`](https://nf-co.re/tools/#downloading-pipelines-for-offline-use) command to download images first, before running the pipeline. Setting the [`NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir`](https://www.nextflow.io/docs/latest/singularity.html?#singularity-docker-hub) Nextflow options enables you to store and re-use the images from a central location for future pipeline runs.
   > - If you are using `conda`, it is highly recommended to use the [`NXF_CONDA_CACHEDIR` or `conda.cacheDir`](https://www.nextflow.io/docs/latest/conda.html) settings to store the environments in a central location for future pipeline runs.

4. Start running your own analysis!


   ```console
   nextflow run CenterForMedicalGeneticsGhent/nf-cmgg-preprocessing --input flowcells.csv --samples samples.csv --outdir <OUTDIR> -profile <docker/singularity/podman/shifter/charliecloud/conda/institute>
   ```

## Flowchart

```mermaid

flowchart TB

FC(["Flowcell (BCL)"])                          --> DEMULTIPLEX
SS([SampleSheet])                               --> DEMULTIPLEX

subgraph DEMULTIPLEX[Demultiplex]
    direction LR
    SAMPLESHEET([SampleSheet])                  --> BCLCONVERT[bcl-convert]
    FLOWCELL([Flowcell])                        --Split by LANE--> BCLCONVERT[bcl-convert]
    BCLCONVERT                                  --> DEMUX_FASTQ([Fastq])
    BCLCONVERT                                  --> DEMULTIPLEX_STATS([Demultiplex Reports])
    DEMUX_FASTQ                                 --> FASTP[FastP]
    FASTP                                       --> DEMUX_MULTIQC[MultiQC]
    DEMULTIPLEX_STATS                           --> DEMUX_MULTIQC[MultiQC]
    DEMUX_MULTIQC                               --> DEMUX_MULTIQC_REPORT([MultiQC Report])
end

DEMULTIPLEX                                     --> RAW_FASTQ([Demultiplexed Fastq per sample per lane])
DEMULTIPLEX                                     --> DEMUX_REPORTS([Demultiplexing reports])
RAW_FASTQ                                       --> ALIGNMENT

subgraph ALIGNMENT
    direction TB
    FASTQ([Fastq per sample per lane])          --> IS_HUMAN{Human data?}
    IS_HUMAN                                    --YES--> NX_SPLITFASTQ[nx SplitFastq]
    IS_HUMAN                                    --NO--> FASTQTOSAM[Picard FastqToSam]
    FASTQTOSAM                                  --> UNALIGNED_BAM([Unaligned BAM])
    NX_SPLITFASTQ                               --split by # reads--> ALIGNER{ALIGNER}
    ALIGNER                                     --> BOWTIE2[Bowtie2-align]
    ALIGNER                                     --> BWAMEM2[Bwamem2 mem]
    ALIGNER                                     --> SNAP[snap-aligner]
    BOWTIE2                                     --> MERGE((Merge bam chunks))
    BWAMEM2                                     --> MERGE((Merge bam chunks))
    SNAP                                        --> MERGE((Merge bam chunks))
    MERGE                                       --> BAMPROCESSOR{BAMPROCESSOR}
    BAMPROCESSOR{BAMPROCESSOR}                  --> BIOBAMBAM[Biobambam]
    BAMPROCESSOR{BAMPROCESSOR}                  --> ELPREP[Elprep]

    subgraph ELPREP_FLOW[Elprep subroutine]
        direction TB
        ELPREP_BAM([BAM])                       --> ELPREP_SPLIT[Elprep split]
        ELPREP_SPLIT                            --split by chromosome-->    ELPREP_FILTER[Elprep filter]
        ELPREP_FILTER                           --sort/mark duplicates-->   ELPREP_MERGE[Elprep merge]
        ELPREP_FILTER                           --BQSR/variant calling-->   ELPREP_MERGE[Elprep merge]
        ELPREP_MERGE                            --> ELPREP_SORTBAM([Postprocessed BAM])
        ELPREP_MERGE                            --> ELPREP_GVCF([gVCF])
    end
    ELPREP                                      --> ELPREP_FLOW
    ELPREP_FLOW                                 --> SORTBAM([Postprocessed BAM])
    ELPREP_FLOW                                 --> ELPREP_GVCF([gVCF])
    ELPREP_FLOW                                 --> MARKDUP_METRICS([Markduplicates Metrics])

    subgraph BIOBAMBAM_FLOW[Biobambam subroutine]
        direction TB
        BIOBAMBAM_BAM([BAM])                    --> SPLIT[Split tool TBD]
        SPLIT                                   --split by chromosome-->    BAMSORMADUP[BamSorMaDup]
        BAMSORMADUP                             --sort/mark duplicates -->  BIOBAMBAM_SORTBAM([Postprocessed BAM])
    end
    BIOBAMBAM                                   --> BIOBAMBAM_FLOW
    BIOBAMBAM_FLOW                              --> SORTBAM
    BIOBAMBAM_FLOW                              --> MARKDUP_METRICS([Markduplicates Metrics])

    SORTBAM                                     -->  BAMQC[BAM QC Tools]
    BAMQC                                       -->  BAM_METRICS([BAM metrics])
    SORTBAM                                     -->  SCRAMBLE[Scramble]
    SORTBAM                                     -->  MOSDEPTH[Mosdepth]
    MOSDEPTH                                    -->  COVERAGE_BED([Coverage BEDs])
    MOSDEPTH                                    -->  COVERAGE_METRICS([Coverage Metrics])
    UNALIGNED_BAM                               -->  SCRAMBLE
    SCRAMBLE                                    -->  ALN_CRAM([CRAM])

    BAM_METRICS                                 -->  ALN_MULTIQC[MultiQC]
    MARKDUP_METRICS                             -->  ALN_MULTIQC
    COVERAGE_METRICS                            -->  ALN_MULTIQC
    ALN_MULTIQC                                 -->  ALN_MULTIQC_REPORT([MultiQC Report])
end

ALIGNMENT                                       --> A_CRAM([CRAM])
ALIGNMENT                                       --> GVCF([gVCF])
ALIGNMENT                                       --> A_BAM_METRICS([BAM metrics])
ALIGNMENT                                       --> A_COVERAGE_METRICS([Coverage metrics])
ALIGNMENT                                       --> A_COVERAGE_BED([Coverage BED])

A_BAM_METRICS                                   --> MQC([Run MultiQC Report])
A_COVERAGE_METRICS                              --> MQC
DEMUX_REPORTS                                   --> MQC

```


## Credits

CenterForMedicalGeneticsGhent/nf-cmgg-preprocessing was originally written by Matthias De Smet.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
