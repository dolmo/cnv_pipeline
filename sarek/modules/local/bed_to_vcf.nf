process BED_TO_VCF {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::python=3.9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'biocontainers/python:3.9--1' }"

    cpus 2  // Added explicit CPU allocation
    memory '4 GB'  // Added explicit memory allocation
    time '1.h'  // Added time limit

    input:
    tuple val(meta), path(bed)
    path reference_fasta
    path reference_fai

    output:
    tuple val(meta), path("*.vcf"), emit: vcf
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "[BED_TO_VCF] Converting ${bed} to VCF format for sample ${meta.id}"
    
    python3 << 'EOF'
import sys
import re

def classify_variant(bed_fields):
    # Check if there are additional columns that might indicate variant type
    if len(bed_fields) >= 4:
        # Look for keywords in the 4th column or beyond
        info_text = ' '.join(bed_fields[3:]).lower()
        
        if 'del' in info_text or 'deletion' in info_text:
            return 'DEL', '<DEL>'
        elif 'dup' in info_text or 'duplication' in info_text or 'amplification' in info_text:
            return 'DUP', '<DUP>'
        elif 'gain' in info_text:
            return 'DUP', '<DUP>'
        elif 'loss' in info_text:
            return 'DEL', '<DEL>'
    
    # If no specific type found, check the length
    # Typically, very large variants might be duplications, smaller ones deletions
    length = int(bed_fields[2]) - int(bed_fields[1])
    if length > 100000:  # > 100kb might be duplication
        return 'DUP', '<DUP>'
    else:
        return 'DEL', '<DEL>'  # Default to deletion for smaller variants

def bed_to_vcf(bed_file, vcf_file, sample_name):
    variant_count = 0
    with open(bed_file) as bed, open(vcf_file, 'w') as vcf:
        # Write comprehensive VCF header
        vcf.write("##fileformat=VCFv4.2\\n")
        vcf.write("##source=JAX-CNV\\n")
        vcf.write("##reference=${reference_fasta}\\n")
        
        # INFO field definitions
        vcf.write("##INFO=<ID=SVTYPE,Number=1,Type=String,Description=\\"Type of structural variant\\">\\n")
        vcf.write("##INFO=<ID=END,Number=1,Type=Integer,Description=\\"End position of the variant\\">\\n")
        vcf.write("##INFO=<ID=SVLEN,Number=1,Type=Integer,Description=\\"Difference in length between REF and ALT alleles\\">\\n")
        vcf.write("##INFO=<ID=IMPRECISE,Number=0,Type=Flag,Description=\\"Imprecise structural variation\\">\\n")
        
        # ALT definitions for structural variants
        vcf.write("##ALT=<ID=DEL,Description=\\"Deletion\\">\\n")
        vcf.write("##ALT=<ID=DUP,Description=\\"Duplication\\">\\n")
        vcf.write("##ALT=<ID=CNV,Description=\\"Copy number variable region\\">\\n")
        
        # FORMAT field definitions
        vcf.write("##FORMAT=<ID=GT,Number=1,Type=String,Description=\\"Genotype\\">\\n")
        vcf.write("##FORMAT=<ID=CN,Number=1,Type=Integer,Description=\\"Copy number\\">\\n")
        
        # Header line
        vcf.write(f"#CHROM\\tPOS\\tID\\tREF\\tALT\\tQUAL\\tFILTER\\tINFO\\tFORMAT\\t{sample_name}\\n")
        
        # Convert BED entries to VCF
        for line_num, line in enumerate(bed, 1):
            if line.startswith('#') or not line.strip():
                continue
            fields = line.strip().split('\\t')
            if len(fields) < 3:
                continue
                
            chrom = fields[0]
            start = int(fields[1]) + 1  # Convert 0-based to 1-based
            end = int(fields[2])
            svlen = end - start
            
            # Classify the variant
            svtype, alt_allele = classify_variant(fields)
            
            # Create variant ID
            vid = f"{svtype}_{chrom}_{start}_{end}"
            
            ref = "N"  # Standard for structural variants
            qual = "."  # Unknown quality
            filter_field = "PASS"
            
            # Build INFO field
            info_parts = [
                f"SVTYPE={svtype}",
                f"END={end}",
                f"SVLEN={svlen if svtype == 'DUP' else -svlen}",  # Negative for deletions
                "IMPRECISE"  # JAX-CNV calls are typically imprecise
            ]
            
            info = ";".join(info_parts)
            
            # FORMAT and sample fields
            format_field = "GT:CN"
            if svtype == "DEL":
                sample_field = "0/1:1"  # Heterozygous deletion, copy number 1
            elif svtype == "DUP":
                sample_field = "0/1:3"  # Heterozygous duplication, copy number 3
            else:
                sample_field = "./.:."  # Unknown
            
            vcf.write(f"{chrom}\\t{start}\\t{vid}\\t{ref}\\t{alt_allele}\\t{qual}\\t{filter_field}\\t{info}\\t{format_field}\\t{sample_field}\\n")
            variant_count += 1

    print(f"Enhanced BED to VCF conversion completed: {variant_count} variants converted")

bed_to_vcf("${bed}", "${prefix}.vcf", "${meta.id}")
EOF

    echo "[BED_TO_VCF] Conversion completed for ${prefix}.vcf"

    cat <<-END_VERSIONS > versions.yml
"${task.process}":
    python: \$(python3 --version | sed 's/Python //')
END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
"${task.process}":
    python: "3.9.0"
END_VERSIONS    
    """
}