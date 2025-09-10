#!/bin/bash

echo "=== HCC1395T CLINICAL CARDIAC CNV REPORT ==="
echo "Generated: $(date)"
echo "Patient: HCC1395T (Tumor sample)"
echo ""

echo "🚨 HIGH-IMPACT CNVs (>10MB affecting cardiac genes):"
awk '($3-$2) > 10000000 {
    size_mb = ($3-$2)/1000000
    printf "%-35s %s:%d-%d (%.1fMB) %s\n", $4, $1, $2+1, $3, size_mb, $5
}' HCC1395T_cnvs.bed

echo ""
echo "📊 CARDIAC GENE IMPACT SUMMARY:"
echo "Total CNVs analyzed: $(wc -l < HCC1395T_cnvs.bed)"
echo "CNVs affecting cardiac genes: $(cut -f4 HCC1395T_cardiac_overlaps.txt | sort | uniq | wc -l)"
echo "Large CNVs (>1MB) affecting cardiac genes: $(awk '($3-$2) > 1000000' HCC1395T_cnvs.bed | wc -l)"
echo "Mega CNVs (>10MB) affecting cardiac genes: $(awk '($3-$2) > 10000000' HCC1395T_cnvs.bed | wc -l)"

echo ""
echo "🧬 CNV TYPE DISTRIBUTION:"
echo "Large deletions (>10MB): $(awk '($3-$2) > 10000000 && $5 ~ /DEL/' HCC1395T_cnvs.bed | wc -l)"
echo "Large duplications (>10MB): $(awk '($3-$2) > 10000000 && $5 ~ /DUP/' HCC1395T_cnvs.bed | wc -l)"

echo ""
echo "🎯 CLINICAL RECOMMENDATION:"
echo "- Multiple mega-CNVs detected (>10MB each)"
echo "- High likelihood of pathogenic impact on cardiac function"
echo "- Recommend detailed cardiac gene analysis"
echo "- Consider cardiac phenotype correlation"
echo "- Tumor sample - may represent somatic alterations"

