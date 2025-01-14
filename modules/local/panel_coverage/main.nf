process PANEL_COVERAGE {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::pybedtools=0.9.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pybedtools:0.9.0--py310h590eda1_1' :
        'biocontainers/pybedtools:0.9.0--py310h590eda1_1' }"

    input:
    tuple val(meta), path(per_base_bed), path(genelist_bed)

    output:
    tuple val(meta), path("*.region.dist.txt"), emit: region_dist

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def genelist_name = genelist_bed.getBaseName()
    template 'panelcoverage.py'
}
