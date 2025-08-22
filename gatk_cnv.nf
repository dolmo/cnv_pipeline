nextflow.enable.dsl=2

// Import the modules
include { GATK4_COLLECTREADCOUNTS } from './modules/nf-core/gatk4/collectreadcounts/main.nf'
include { GATK4_DETERMINEGERMLINECONTIGPLOIDY } from './modules/nf-core/gatk4/determinegermlinecontigploidy/main.nf'
include { GATK4_GERMLINECNVCALLER } from './modules/nf-core/gatk4/germlinecnvcaller/main.nf'

workflow {

    
    ch_reads = tuple([ id:"test", single_end:false ], file(params.bam), file(params.bai),params.intervals) 
    ch_intervals = Channel.value(file(params.intervals))

    ch_fasta = tuple('sample1', file(params.reference))
    ch_fai   = tuple('sample1', file(params.fai))
    ch_dict  = tuple('sample1', file(params.dict))

    GATK4_COLLECTREADCOUNTS(
        ch_reads,
    ch_fasta,
    ch_fai,
    ch_dict
        )
        
    // hdf5_ch = GATK4_COLLECTREADCOUNTS.out.hdf5.map { meta, hdf5 -> hdf5 }

    ch_counts_and_intervals = GATK4_COLLECTREADCOUNTS.out.hdf5.combine(ch_intervals)

    
    ch_for_ploidy = ch_counts_and_intervals.map { meta, hdf5, bed ->
        [ meta, hdf5, bed, [] ]  // The `[]` satisfies the 'exclude_beds' input
    }

    ch_for_ploidy.view() 

    
    GATK4_DETERMINEGERMLINECONTIGPLOIDY(
    ch_for_ploidy,
    tuple( [ id:"test", single_end:false ], [] ), // Input for 'ploidy_model'
    []                                            // Corrected input for 'contig_ploidy_table'
)
    GATK4_DETERMINEGERMLINECONTIGPLOIDY.out.calls.view()

    ch_counts_for_calling = GATK4_COLLECTREADCOUNTS.out.hdf5
    ch_ploidy_calls       = GATK4_DETERMINEGERMLINECONTIGPLOIDY.out.calls

    ch_counts_for_calling.combine( ch_ploidy_calls, by: 0 )
        .set { ch_for_cnv_caller }

    GATK4_GERMLINECNVCALLER(
        ch_for_cnv_caller
    )
}