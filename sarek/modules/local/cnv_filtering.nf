include { FILTER_CNV_SIZE    } from '../../modules/local/filter_cnv_size'
include { FILTER_CNV_QUALITY } from '../../modules/local/filter_cnv_quality'

workflow CNV_FILTERING {
    take:
    ch_vcf          // channel: [meta, vcf]
    min_size        // val: minimum CNV size
    max_size        // val: maximum CNV size
    
    main:
    ch_versions = Channel.empty()
    
    // Step 1: Filter by size
    FILTER_CNV_SIZE(ch_vcf, min_size, max_size)
    ch_versions = ch_versions.mix(FILTER_CNV_SIZE.out.versions)
    
    // Step 2: Filter by quality
    FILTER_CNV_QUALITY(FILTER_CNV_SIZE.out.filtered_vcf)
    ch_versions = ch_versions.mix(FILTER_CNV_QUALITY.out.versions)
    
    emit:
    filtered_vcf = FILTER_CNV_QUALITY.out.quality_filtered_vcf
    versions     = ch_versions
}