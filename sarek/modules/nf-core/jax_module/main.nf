process JAX_CNV {
    tag "$meta.id"
    label 'process_medium'

    container params.jax_cnv_sif

    cpus 8  // CHANGED: Increased from 4
    memory '16 GB'  // CHANGED: Increased from 8
    time '12.h'  // ADDED: Explicit time limit
    publishDir "results/jax_cnv", mode: 'copy'

    input:
    tuple val(meta), path(cram)
    path ref
    path ref_fai
    path jax_script

    output:
    tuple val(meta), path("*.bed"), emit: cnv_bed
    path "*.log", emit: cnv_log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    set -euo pipefail
    export PATH=/opt/jellyfish/bin:/tools/JAX-CNV/bin:\$PATH

    echo "[JAX_CNV] sample prefix: ${prefix}"
    echo "[JAX_CNV] ref: $ref"
    echo "[JAX_CNV] threads: ${task.cpus}"

    # ensure samtools on PATH
    if ! command -v samtools >/dev/null 2>&1; then
      echo "[JAX_CNV] ERROR: samtools not available in container PATH" >&2
      exit 2
    fi

    # Convert CRAM->BAM if needed or copy BAM
    if [[ "$cram" == *.cram ]]; then
      echo "[JAX_CNV] converting CRAM -> BAM"
      samtools view -T "$ref" -b -@ ${task.cpus} -o ${prefix}_unsorted.bam "$cram"  # CHANGED: Added -@ ${task.cpus}
    else
      echo "[JAX_CNV] copying BAM into workdir"
      cp "$cram" ${prefix}_unsorted.bam
    fi

    # Sort & index
    samtools sort -@ ${task.cpus} -o ${prefix}_sorted.bam ${prefix}_unsorted.bam
    samtools index ${prefix}_sorted.bam

    # Check for jellyfish
    if command -v jellyfish >/dev/null 2>&1; then
      JF_CMD=jellyfish
    elif [[ -x /opt/jellyfish/bin/jellyfish ]]; then
      JF_CMD=/opt/jellyfish/bin/jellyfish
    else
      echo "[JAX_CNV] ERROR: jellyfish not found in container PATH" >&2
      exit 3
    fi

    # Count kmers
    echo "[JAX_CNV] counting kmers with \$JF_CMD"
    \$JF_CMD count -m 25 -s 1G -t ${task.cpus} -C -o ${prefix}.jellydb "$ref"  # CHANGED: -s 100M to -s 1G

    # Dump .jf to .kmer FASTA
    echo "[JAX_CNV] dumping jellyfish db -> .kmer_out"
    JAX-CNV GrabJellyfishKmer --ascii -i ${prefix}.jellydb -f "$ref" -o ${prefix}.kmer_out

    # Run JAX-CNV GetCnvSignal
    echo "[JAX_CNV] running GetCnvSignal"
    JAX-CNV GetCnvSignal -k ${prefix}.kmer_out -f "$ref" -b ${prefix}_sorted.bam -o ${prefix}.bed --log ${prefix}.log

    # cleanup
    rm -f ${prefix}_unsorted.bam ${prefix}.jellydb ${prefix}.kmer_out

    # FIXED: Properly capture and format versions
    SAMTOOLS_VERSION=\$(samtools --version 2>&1 | head -1 | sed 's/samtools //' | tr -d '\\n\\r')
    JELLYFISH_VERSION=\$(\$JF_CMD --version 2>&1 | head -1 | sed 's/jellyfish //' | tr -d '\\n\\r' || echo "unknown")
    JAX_VERSION=\$(JAX-CNV --version 2>&1 | head -1 | sed 's/.*[Vv]ersion[: ]*//' | tr -d '\\n\\r' || echo "unknown")
    
    # Ensure versions are not empty and contain only valid characters
    SAMTOOLS_VERSION=\${SAMTOOLS_VERSION:-"unknown"}
    JELLYFISH_VERSION=\${JELLYFISH_VERSION:-"unknown"}
    JAX_VERSION=\${JAX_VERSION:-"unknown"}
    
    # Remove any problematic characters
    SAMTOOLS_VERSION=\$(echo "\$SAMTOOLS_VERSION" | sed 's/[^a-zA-Z0-9._-]//g')
    JELLYFISH_VERSION=\$(echo "\$JELLYFISH_VERSION" | sed 's/[^a-zA-Z0-9._-]//g')
    JAX_VERSION=\$(echo "\$JAX_VERSION" | sed 's/[^a-zA-Z0-9._-]//g')
    
    cat <<-END_VERSIONS > versions.yml
"${task.process}":
    samtools: "\$SAMTOOLS_VERSION"
    jellyfish: "\$JELLYFISH_VERSION"
    jax_cnv: "\$JAX_VERSION"
END_VERSIONS

    echo "[JAX_CNV] finished: ${prefix}"
    """
}