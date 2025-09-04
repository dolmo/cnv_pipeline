#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Import the JAX CNV module
include { JAX_CNV } from './main.nf'

workflow TEST_JAX_CNV {
    
    // Create test input channel
    // Format: tuple val(meta), file(input_bam), file(reference_fasta), val(jax_cnv_sif), val(threads), val(do_preprocessing)
    
    def meta = [id: 'test_sample']
    def input_bam = file(params.test_bam ?: 'test_data/test.bam')
    def reference_fasta = file(params.test_reference ?: 'test_data/test_ref.fa')
    def jax_cnv_sif = params.jax_cnv_sif ?: '/path/to/jax_cnv.sif'
    def threads = params.threads ?: 4
    def do_preprocessing = params.do_preprocessing ?: true
    
    // Create input channel
    ch_input = Channel.of([meta, input_bam, reference_fasta, jax_cnv_sif, threads, do_preprocessing])
    
    // Run JAX CNV
    JAX_CNV(ch_input)
    
    // View results
    JAX_CNV.out.cnv_results.view { result_meta, bed, log, versions ->
        "JAX CNV Results for ${result_meta.id}:\n  BED: ${bed}\n  LOG: ${log}\n  VERSIONS: ${versions}"
    }
}

workflow {
    TEST_JAX_CNV()
}