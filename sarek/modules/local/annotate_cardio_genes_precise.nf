process ANNOTATE_CARDIAC_GENES_PRECISE {
    tag "$meta.id"
    
    input:
    tuple val(meta), path(cnv_vcf)
    path cardiac_genes_bed
    
    output:
    tuple val(meta), path("*.precise_cardiac.vcf"), emit: annotated_vcf
    tuple val(meta), path("*.cardiac_overlaps.txt"), emit: overlap_report
    
    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Convert VCF to BED for overlap analysis
    grep -v "^#" ${cnv_vcf} | awk 'BEGIN{OFS="\\t"} {
        if(\$8 ~ /END=/) {
            match(\$8, /END=([0-9]+)/, arr)
            end = arr[1]
        } else {
            end = \$2 + length(\$4)
        }
        print \$1, \$2-1, end, \$3, \$5, \$8
    }' > cnvs.bed
    
    # Find precise overlaps
    bedtools intersect -a cnvs.bed -b ${cardiac_genes_bed} -wa -wb > overlaps.txt
    
    # Annotate VCF with cardiac gene information
    python3 << 'PYTHON_EOF'
import sys

# Read overlaps
overlaps = {}
with open('overlaps.txt', 'r') as f:
    for line in f:
        fields = line.strip().split('\\t')
        cnv_id = fields[3]
        cardiac_region = f"{fields[6]}:{fields[7]}-{fields[8]}"
        if cnv_id not in overlaps:
            overlaps[cnv_id] = []
        overlaps[cnv_id].append(cardiac_region)

# Annotate VCF
with open('${cnv_vcf}', 'r') as infile, open('${prefix}.precise_cardiac.vcf', 'w') as outfile:
    for line in infile:
        if line.startswith('#'):
            if line.startswith('##INFO=<ID=CARDIO_GENES'):
                continue  # Skip old annotation
            elif line.startswith('#CHROM'):
                outfile.write('##INFO=<ID=CARDIAC_REGIONS,Number=.,Type=String,Description="Overlapping cardiac gene regions">\\n')
            outfile.write(line)
        else:
            fields = line.strip().split('\\t')
            cnv_id = fields[2]
            if cnv_id in overlaps:
                cardiac_annotation = f"CARDIAC_REGIONS={','.join(overlaps[cnv_id])}"
                if 'CARDIO_GENES=' in fields[7]:
                    fields[7] = fields[7] + ';' + cardiac_annotation
                else:
                    fields[7] = fields[7] + ';' + cardiac_annotation
            outfile.write('\\t'.join(fields) + '\\n')
PYTHON_EOF
    
    # Create overlap summary report
    echo "CNV_ID\\tCNV_Location\\tCardiac_Regions\\tOverlap_Count" > ${prefix}.cardiac_overlaps.txt
    awk 'BEGIN{OFS="\\t"} {
        cnv_location = \$1 ":" \$2+1 "-" \$3
        cardiac_region = \$7 ":" \$8 "-" \$9
        print \$4, cnv_location, cardiac_region, "1"
    }' overlaps.txt >> ${prefix}.cardiac_overlaps.txt
    """
}