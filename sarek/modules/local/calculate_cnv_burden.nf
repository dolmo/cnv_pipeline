process CALCULATE_CNV_BURDEN {
    tag "$meta.id"
    label 'process_low'

    container params.jax_cnv_sif  
    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.burden.txt"), emit: burden_stats
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "[CALCULATE_CNV_BURDEN] Calculating CNV burden for ${meta.id}"
    
    # Create header
    echo -e "Sample\\tTotal_CNVs\\tDeletions\\tDuplications\\tTotal_BP_Affected\\tCardio_Gene_CNVs\\tAvg_CNV_Size" > ${prefix}.burden.txt
    
    # Calculate statistics
    TOTAL=\$(bcftools view -H ${vcf} | wc -l)
    DELS=\$(bcftools view -H -i 'INFO/SVTYPE="DEL"' ${vcf} | wc -l || echo "0")
    DUPS=\$(bcftools view -H -i 'INFO/SVTYPE="DUP"' ${vcf} | wc -l || echo "0")
    
    # Calculate total base pairs affected - FIXED escaping
    TOTAL_BP=\$(bcftools query -f '%INFO/SVLEN\\n' ${vcf} | awk '{sum+=(\$1<0?-\$1:\$1)} END {print (sum ? sum : 0)}')
    
    # Count CNVs overlapping cardiomyopathy genes
    CARDIO_CNVs=\$(bcftools view -H ${vcf} | grep -c "CARDIO_GENES=" || echo "0")
    
    # Calculate average CNV size
    if [[ \$TOTAL -gt 0 ]]; then
        AVG_SIZE=\$(echo "scale=2; \$TOTAL_BP / \$TOTAL" | bc -l || echo "0")
    else
        AVG_SIZE="0"
    fi
    
    echo -e "${meta.id}\\t\$TOTAL\\t\$DELS\\t\$DUPS\\t\$TOTAL_BP\\t\$CARDIO_CNVs\\t\$AVG_SIZE" >> ${prefix}.burden.txt
    
    echo "[CALCULATE_CNV_BURDEN] ${meta.id}: \$TOTAL total CNVs (\$DELS deletions, \$DUPS duplications), \$CARDIO_CNVs affecting cardio genes"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -1 | sed 's/bcftools //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo -e "Sample\\tTotal_CNVs\\tDeletions\\tDuplications\\tTotal_BP_Affected\\tCardio_Gene_CNVs\\tAvg_CNV_Size" > ${prefix}.burden.txt
    echo -e "${meta.id}\\t10\\t5\\t5\\t50000\\t2\\t5000" >> ${prefix}.burden.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: "1.17"
    END_VERSIONS
    """
}