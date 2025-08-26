#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: $0 --ref REFERENCE.fa --input SAMPLE.cram|SAMPLE.bam --threads N --jax_cnv path/to/jax_cnv.sif [--skip-bam]"
    echo ""
    echo "Options:"
    echo "  --skip-bam      Skip BAM conversion/sorting/indexing; input must be a sorted BAM"
    exit 1
}

# Default values
REF=""
INPUT=""
THREADS=1
JAX_CNV_SIF=""
SKIP_BAM=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ref) REF="$2"; shift 2 ;;
        --input) INPUT="$2"; shift 2 ;;
        --threads) THREADS="$2"; shift 2 ;;
        --jax_cnv) JAX_CNV_SIF="$2"; shift 2 ;;
        --skip-bam) SKIP_BAM=1; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown argument: $1"; usage ;;
    esac
done

# Check required arguments
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

singularity exec --bind "$(pwd):$(pwd)" "$JAX_CNV_SIF" bash -c "
set -euo pipefail

if [[ $SKIP_BAM -eq 0 ]]; then
    echo '[Step 1/3] Prepare BAM...'
    if [[ \"$INPUT\" == *.cram ]]; then
        echo 'Converting CRAM -> BAM: $INPUT -> $UNSORTED_BAM'
        /usr/bin/samtools view -T \"$REF\" -b -o \"$UNSORTED_BAM\" \"$INPUT\"
    else
        echo 'Copying BAM for processing: $INPUT -> $UNSORTED_BAM'
        cp \"$INPUT\" \"$UNSORTED_BAM\"
    fi

    echo 'Sorting BAM...'
    /usr/bin/samtools sort -@ $THREADS -o \"$SORTED_BAM\" \"$UNSORTED_BAM\"

    echo 'Indexing BAM...'
    /usr/bin/samtools index \"$SORTED_BAM\"
else
    echo '[Step 1/3] Skipping BAM prep; assuming input is a sorted BAM.'
    SORTED_BAM=\"$INPUT\"
fi

echo '[Step 2/3] Count kmers with Jellyfish...'
/usr/bin/jellyfish count -m 25 -s 100M -t $THREADS -C -o \"$JELLY_DB\" \"$REF\"

echo '[Step 3/3] Run JAX-CNV...'
/tools/JAX-CNV/bin/JAX-CNV GrabJellyfishKmer --ascii -i \"$JELLY_DB\" -f \"$REF\" -o \"$KMER_OUT\"
/tools/JAX-CNV/bin/JAX-CNV GetCnvSignal -k \"$KMER_OUT\" -f \"$REF\" -b \"$SORTED_BAM\" -o \"$BED_OUT\" --log \"$LOG_OUT\"

echo '---'
echo 'Pipeline complete!'
echo 'Results:'
echo '  CNV BED file: $BED_OUT'
echo '  CNV Log file: $LOG_OUT'
echo '---'
"
