process FILTER_CNV_QUALITY {
    tag "$meta.id"
    label 'process_low'

   container params.jax_cnv_sif  

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.quality_filtered.vcf"), emit: quality_filtered_vcf
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''
    """
    echo "[FILTER_CNV_QUALITY] Filtering CNVs by quality for ${meta.id}"
    
    # Filter for PASS variants only (you can customize this filter)
    bcftools view -f PASS ${args} ${vcf} > ${prefix}.quality_filtered.vcf
    
    # Count variants before and after filtering
    TOTAL_BEFORE=\$(bcftools view -H ${vcf} | wc -l)
    TOTAL_AFTER=\$(bcftools view -H ${prefix}.quality_filtered.vcf | wc -l)
    
    echo "[FILTER_CNV_QUALITY] ${meta.id}: \$TOTAL_BEFORE variants before filtering, \$TOTAL_AFTER after quality filtering"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -1 | sed 's/bcftools //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.quality_filtered.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: "1.17"
    END_VERSIONS
    """
}