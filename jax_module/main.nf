#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
 * JAX_CNV: Run JAX-CNV CNV caller with optional preprocessing.
 * Inputs:
 *   - meta:      Sample metadata (map)
 *   - input_bam: Input BAM or CRAM file
 *   - reference_fasta: Reference FASTA file
 *   - jax_cnv_sif: Path to JAX-CNV Singularity image
 *   - threads:   Number of threads to use
 *   - do_preprocessing: Boolean, whether to run CRAM/BAM preprocessing
 * Outputs:
 *   - tuple(meta, *.bed, *.log, versions.yml)
 */

process JAX_CNV {
    tag "${meta.id ?: input_bam.baseName}"

    input:
        tuple val(meta), file(input_bam), file(reference_fasta), val(jax_cnv_sif), val(threads), val(do_preprocessing)

    output:
        tuple val(meta), file("*.bed"), file("*.log"), file("versions.yml"), emit: cnv_results

    container "${jax_cnv_sif}"

    script:
    """
    # Set up file names
    BASE_NAME=\$(basename "${input_bam}" .bam)
    BASE_NAME=\${BASE_NAME%.cram}
    UNSORTED_BAM="\${BASE_NAME}_unsorted.bam"
    SORTED_BAM="\${BASE_NAME}_sorted.bam"
    JELLY_DB="\${BASE_NAME}.jellydb"
    KMER_OUT="\${BASE_NAME}.kmer_out"
    BED_OUT="\${BASE_NAME}.bed"
    LOG_OUT="\${BASE_NAME}.log"

    # Step 1-3: Preprocessing (optional)
    if [ "${do_preprocessing}" = "true" ]; then
        if [[ "${input_bam}" == *.cram ]]; then
            /usr/bin/samtools view -T ${reference_fasta} -b -o "\${UNSORTED_BAM}" ${input_bam}
        else
            cp ${input_bam} "\${UNSORTED_BAM}"
        fi
        /usr/bin/samtools sort -@ ${threads} "\${UNSORTED_BAM}" -o "\${SORTED_BAM}"
        /usr/bin/samtools index "\${SORTED_BAM}"
    else
        cp ${input_bam} "\${SORTED_BAM}"
        /usr/bin/samtools index "\${SORTED_BAM}"
    fi

    # Step 4: Jellyfish count
    /usr/bin/jellyfish count -m 25 -s 100M -t ${threads} -C -o "\${JELLY_DB}" ${reference_fasta}

    # Step 5: Dump .jf to .kmer FASTA
    /tools/JAX-CNV/bin/JAX-CNV GrabJellyfishKmer --ascii -i "\${JELLY_DB}" -f ${reference_fasta} -o "\${KMER_OUT}"

    # Step 6: Run JAX-CNV
    /tools/JAX-CNV/bin/JAX-CNV GetCnvSignal -k "\${KMER_OUT}" -f ${reference_fasta} -b "\${SORTED_BAM}" -o "\${BED_OUT}" --log "\${LOG_OUT}"

    # Write versions
    echo "jax_cnv: \$(${jax_cnv_sif} --version 2>&1 | head -1)" > versions.yml
    echo "samtools: \$(/usr/bin/samtools --version | head -1)" >> versions.yml
    echo "jellyfish: \$(/usr/bin/jellyfish --version | head -1)" >> versions.yml
    """
}

stub:
"""
touch test.bed test.log versions.yml
"""