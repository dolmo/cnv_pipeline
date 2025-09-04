#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Test workflow for JAX CNV module using stub mode
// This allows testing the workflow logic without actual execution

// Import the JAX CNV module
include { JAX_CNV } from './main.nf'

workflow TEST_JAX_CNV_STUB {
    
    // Create test input channel
    def meta = [id: 'test_sample']
    def input_bam = file('test_data/test.sam')  // Using SAM for now
    def reference_fasta = file('test_data/test_ref.fa')
    def jax_cnv_sif = '/path/to/jax_cnv.sif'
    def threads = 4
    def do_preprocessing = true
    
    // Create input channel
    ch_input = Channel.of([meta, input_bam, reference_fasta, jax_cnv_sif, threads, do_preprocessing])
    
    // Run JAX CNV in stub mode
    JAX_CNV(ch_input)
    
    // View results
    JAX_CNV.out.cnv_results.view { sample_meta, bed, log, versions ->
        "JAX CNV Results for ${sample_meta.id}:\n  BED: ${bed}\n  LOG: ${log}\n  VERSIONS: ${versions}"
    }
}

workflow {
    TEST_JAX_CNV_STUB()
}
