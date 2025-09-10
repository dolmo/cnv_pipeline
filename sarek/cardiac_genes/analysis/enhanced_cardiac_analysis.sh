#!/bin/bash

echo "=== ENHANCED CARDIAC CNV ANALYSIS ==="
echo "Using both transcript regions AND gene names"
echo ""

# First, analyze with your existing BED regions
echo "📊 TRANSCRIPT-LEVEL ANALYSIS:"
bedtools intersect -a HCC1395T_cnvs.bed -b cardiac_genes/cardiac_gene_list_V2_intervals.bed -wa -wb > transcript_overlaps.txt
echo "CNVs overlapping cardiac transcripts: $(cut -f4 transcript_overlaps.txt | sort | uniq | wc -l)"

# Then, we'll add gene-name based analysis
echo ""
echo "🧬 GENE-LEVEL ANALYSIS:"
echo "Major cardiac genes to check:"
echo "- MYH7 (Hypertrophic cardiomyopathy)"
echo "- MYBPC3 (Hypertrophic cardiomyopathy)" 
echo "- TNNT2 (Hypertrophic cardiomyopathy)"
echo "- TTN (Dilated cardiomyopathy)"
echo "- DSP (Arrhythmogenic cardiomyopathy)"
echo "- PKP2 (Arrhythmogenic cardiomyopathy)"
echo "- RYR2 (Catecholaminergic polymorphic ventricular tachycardia)"
echo "- SCN5A (Brugada syndrome, Long QT)"

# Create summary of major findings
echo ""
echo "🎯 TOP CLINICAL TARGETS:"
echo "Large CNVs (>10MB) affecting cardiac regions:"
awk '($3-$2) > 10000000 {
    size_mb = ($3-$2)/1000000
    printf "%-35s %s:%d-%d (%.1fMB) %s\n", $4, $1, $2+1, $3, size_mb, $5
}' HCC1395T_cnvs.bed

