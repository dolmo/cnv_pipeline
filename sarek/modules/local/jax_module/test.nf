#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Test workflow for JAX CNV module
include { JAX_CNV } from './main.nf'

workflow {
    // Create test input
    def meta = [id: 'test']
    def input_bam = file('test.bam')
    def reference_fasta = file('test.fa')
    def jax_cnv_sif = '/path/to/jax_cnv.sif'
    def threads = 4
    def do_preprocessing = true
    
    ch_input = Channel.of([meta, input_bam, reference_fasta, jax_cnv_sif, threads, do_preprocessing])
    
    JAX_CNV(ch_input)
}