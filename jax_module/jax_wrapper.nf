process JAX_CNV {
    publishDir "results/jax_cnv", mode: 'copy'

    cpus 4
    memory '8 GB'

    // Singularity container handled automatically
    container params.sif_path

    input:
        path bam
        path ref
        path jax_script
        path sif_path   

    output:
        path "*.bed", emit: cnv_bed
        path "*.log", emit: cnv_log

    script:
    """
    bash ${jax_script} \
        --ref $ref \
        --input $bam \
        --threads ${task.cpus} \
        --jax_cnv $sif_path
    """
}


workflow {

    ch_bams = Channel.value(file(params.bam))
    ch_ref  = Channel.value(file(params.ref))
    ch_script = Channel.value(file('jax_pipeline_working.sh'))
    ch_sif = Channel.value(file(params.sif_path))

    JAX_CNV(ch_bams, ch_ref, ch_script, ch_sif)
}
