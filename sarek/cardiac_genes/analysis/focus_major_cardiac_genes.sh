#!/bin/bash

echo "=== MAJOR CARDIAC GENE ANALYSIS ==="

# Define major cardiac genes with their typical chromosomal locations
declare -A major_genes
major_genes[MYH7]="chr14:23400000-23450000"
major_genes[MYBPC3]="chr11:47350000-47380000"
major_genes[TNNT2]="chr1:201300000-201350000"
major_genes[TTN]="chr2:178500000-178850000"
major_genes[DSP]="chr6:7540000-7590000"
major_genes[PKP2]="chr12:32850000-32890000"
major_genes[RYR2]="chr1:237200000-237950000"
major_genes[SCN5A]="chr3:38550000-38650000"

echo "Checking your large CNVs against major cardiac genes:"
echo ""

for gene in "${!major_genes[@]}"; do
    location=${major_genes[$gene]}
    chr=$(echo $location | cut -d: -f1)
    start=$(echo $location | cut -d: -f2 | cut -d- -f1)
    end=$(echo $location | cut -d: -f2 | cut -d- -f2)
    
    echo "=== $gene ($location) ==="
    
    # Check if any of your CNVs overlap this region
    overlaps=$(awk -v chr="$chr" -v start="$start" -v end="$end" '
        $1 == chr && (($2 <= end && $3 >= start)) {
            size_mb = ($3-$2)/1000000
            printf "  %s: %s:%d-%d (%.1fMB) %s\n", $4, $1, $2+1, $3, size_mb, $5
        }' HCC1395T_cnvs.bed)
    
    if [ -n "$overlaps" ]; then
        echo "$overlaps"
    else
        echo "  No CNVs detected in this region"
    fi
    echo ""
done

