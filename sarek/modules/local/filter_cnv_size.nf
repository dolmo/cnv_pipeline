process FILTER_CNV_SIZE {
    tag "$meta.id"
    label 'process_low'

    container params.jax_cnv_sif  // Use your custom container

    input:
    tuple val(meta), path(vcf)
    val min_size
    val max_size

    output:
    tuple val(meta), path("*.size_filtered.vcf"), emit: filtered_vcf
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "[FILTER_CNV_SIZE] Filtering CNVs by size: ${min_size} - ${max_size} bp"
    
    bcftools view -i 'abs(INFO/SVLEN) >= ${min_size} && abs(INFO/SVLEN) <= ${max_size}' \\
        ${vcf} > ${prefix}.size_filtered.vcf
    
    # Count variants before and after filtering
    TOTAL_BEFORE=\$(bcftools view -H ${vcf} | wc -l)
    TOTAL_AFTER=\$(bcftools view -H ${prefix}.size_filtered.vcf | wc -l)
    
    echo "[FILTER_CNV_SIZE] ${meta.id}: \$TOTAL_BEFORE variants before filtering, \$TOTAL_AFTER after size filtering"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -1 | sed 's/bcftools //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.size_filtered.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: "1.17"
    END_VERSIONS
    """
}