# Point of this document
    - In this document we are attempting to understand the header file of some vcf files and understanding some terms in the annotated tsv file
    - We need this because we are currently confused on the filtering process



# Filter Field
    - The filter field is the bare minimum checks for all caller specific quality, this includes read depth, quality and ploidy consistency
    - We shouldn´t rely on just this but its good to get rid of some almost assured low quality variants
    - We would like to get rid of:
        - Max Depth: 
            - More than 3x the median depth, aka low confidence in variant call
        - Ploidy:
            - Inconsistent genotype expectation 
        - MaxMQ0Frac
            - Poor aligntment near breakpoints
        - NoPairSupport
            - No paired end reads support SV, usually means its noise
        - MinQual
            - Fails to meet more than a quality of 20
        - SampleFT/MinGQ/HomRef
            - Individual sample quality

# INFO Fields
    - SVTYPE
        - Classifies each variant by type of structural variant
        - DEL,DUP,INS,INV,BND(translocations)
            - We might want to filter out complicated CNVs like Inversions and Translocations
    - SVLEN
        - Length of a structural variant or inversion
        - Useful for filtering out tiny events that might be noise
    - IMPRECISE
        - This signals if breakpoints are fuzzy (not exact)
    - CIPOS, CIEND
        - Confidence interval around POS and END, if intervals are too wide then we are uncertain about where a SV starts and ends



# FORMAT fields
    - GT:FT:GQ:PL:PR
        -Genotype
            -
        -FT-Filter
            - 
        - GQ
            - Genotype Quality
                - Confidence in identification of genotype quality
                -Should look into this
        - PR/SR
            - Paired end and split read support for variant
            - Low support = low confidence
            - Should look into this

        

# Repository for CNVs
    - Coriell Insitute for Medical Research
    - Genome in a bottle