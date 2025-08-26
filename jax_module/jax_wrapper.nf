process JAX_CNV {
    tag "$sample_id"
    publishDir "results/jax_cnv", mode: 'copy'

    cpus 4

    input:
    tuple val(sample_id), path(bam)
    path ref
    path jax_cnv_sif

    output:
    path "*.bed", emit: cnv_bed
    path "*.log", emit: cnv_log

    script:
    """
    bash jax_pipeline.sh \
        --ref $ref \
        --input $bam \
        --threads ${task.cpus} \
        --jax_cnv $jax_cnv_sif \
        --skip-bam
    """
}
