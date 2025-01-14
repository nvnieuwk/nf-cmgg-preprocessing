process SAMTOOLS_SORMADUP {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::samtools=1.17"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.17--h00cdaf9_0' :
        'quay.io/biocontainers/samtools:1.17--h00cdaf9_0' }"

    input:
    tuple val(meta), path(input)
    tuple val(meta2), path(fasta)

    output:
    tuple val(meta), path("*.{bam,cram}")   , emit: bam
    tuple val(meta), path("*.{bai,crai}")   , optional:true, emit: bam_index
    tuple val(meta), path("*.metrics")      , emit: metrics
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extension = args.contains("--output-fmt sam") ? "sam" :
                    args.contains("--output-fmt bam") ? "bam" :
                    args.contains("--output-fmt cram") ? "cram" :
                    "bam"
    def reference = fasta ? "--reference ${fasta}" : ""
    def sort_memory = (task.memory.mega/task.cpus*0.75).intValue()

    """
    samtools cat \\
        --threads $task.cpus \\
        ${input}  \\
    | \\
    samtools collate \\
        -O \\
        -u \\
        -T ${prefix} \\
        --threads $task.cpus \\
        ${reference} \\
        - \\
    | \\
    samtools fixmate \\
        -m \\
        -u \\
        --threads $task.cpus \\
        - \\
        - \\
    | \\
    samtools sort \\
        -u \\
        -T ${prefix} \\
        --threads $task.cpus \\
        -m ${sort_memory}M \\
        - \\
    | \\
    samtools markdup \\
        -T ${prefix} \\
        -f ${prefix}.metrics \\
        --threads $task.cpus \\
        --write-index \\
        $args \\
        - \\
        ${prefix}.${extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
