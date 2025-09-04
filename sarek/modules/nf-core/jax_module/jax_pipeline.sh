#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: $0 --ref REFERENCE.fa --input SAMPLE.cram|SAMPLE.bam --threads N --jax_cnv path/to/jax_cnv.sif"
    exit 1
}

REF=""
INPUT=""
THREADS=1
JAX_CNV_SIF=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ref) REF="$2"; shift 2 ;;
        --input) INPUT="$2"; shift 2 ;;
        --threads) THREADS="$2"; shift 2 ;;
        --jax_cnv) JAX_CNV_SIF="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown argument: $1"; usage ;;
    esac
done

if [[ -z "$REF" || -z "$INPUT" || -z "$JAX_CNV_SIF" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

if [[ ! -f "$REF" ]]; then
    echo "Error: Reference FASTA '$REF' not found."
    exit 1
fi

if [[ ! -f "$INPUT" ]]; then
    echo "Error: Input file '$INPUT' not found."
    exit 1
fi

BASE_NAME=$(basename "$INPUT" .cram)
BASE_NAME=$(basename "$BASE_NAME" .bam)

UNSORTED_BAM="${BASE_NAME}_unsorted.bam"
SORTED_BAM="${BASE_NAME}_sorted.bam"
JELLY_DB="${BASE_NAME}.jellydb"
KMER_OUT="${BASE_NAME}.kmer_out"
BED_OUT="${BASE_NAME}.bed"
LOG_OUT="${BASE_NAME}.log"

echo "---"
echo "Starting JAX-CNV Pipeline for $INPUT..."
echo "---"

singularity exec --bind "$(pwd):$(pwd)" "$JAX_CNV_SIF" bash -c '
set -euo pipefail

echo "[Step 1/6] Convert CRAM to BAM or copy BAM..."
if [[ "'"$INPUT"'" == *.cram ]]; then
    echo "  Converting CRAM to BAM: '\'''"$INPUT"''\'' -> '\'''"$UNSORTED_BAM"''\''"
    /usr/bin/samtools view -T "'"$REF"'" -b -o "'"$UNSORTED_BAM"'" "'"$INPUT"'"
else
    echo "  Copying BAM file to '\'''"$UNSORTED_BAM"''\'' for processing..."
    cp "'"$INPUT"'" "'"$UNSORTED_BAM"'"
fi

echo "[Step 2/6] Sort BAM..."
echo "  Sorting '\'''"$UNSORTED_BAM"''\'' -> '\'''"$SORTED_BAM"''\''"
/usr/bin/samtools sort -@ '"$THREADS"' "'"$UNSORTED_BAM"'" "'"$SORTED_BAM"'" 

echo "[Step 3/6] Index BAM..."
echo "  Indexing '\'''"$SORTED_BAM"''\''"
/usr/bin/samtools index "'"$SORTED_BAM"'"

echo "[Step 4/6] Count kmers with Jellyfish..."
echo "  Counting kmers from '\'''"$REF"''\'' -> '\'''"$JELLY_DB"''\''"
/usr/bin/jellyfish count -m 25 -s 100M -t '"$THREADS"' -C -o "'"$JELLY_DB"'" "'"$REF"'"

echo "[Step 5/6] Dump .jf to .kmer FASTA..."
echo "  Dumping kmer counts to '\'''"$KMER_OUT"''\''"
/tools/JAX-CNV/bin/JAX-CNV GrabJellyfishKmer --ascii -i "'"$JELLY_DB"'" -f "'"$REF"'" -o "'"$KMER_OUT"'"

echo "[Step 6/6] Run JAX-CNV..."
echo "  Analyzing CNV signal: '\'''"$SORTED_BAM"''\'' -> '\'''"$BED_OUT"''\'' and '\'''"$LOG_OUT"''\''"
/tools/JAX-CNV/bin/JAX-CNV GetCnvSignal -k "'"$KMER_OUT"'" -f "'"$REF"'" -b "'"$SORTED_BAM"'" -o "'"$BED_OUT"'" --log "'"$LOG_OUT"'"

echo "---"
echo "Pipeline complete!"
echo "Results:"
echo "  CNV BED file: '"$BED_OUT"'"
echo "  CNV Log file: '"$LOG_OUT"'"
echo "---"
'

