#!/bin/bash

# Script to create minimal test BAM file for JAX CNV testing

cd test_data

# Create SAM header
cat > test.sam << 'EOF'
@HD	VN:1.6	SO:coordinate
@SQ	SN:chr1	LN:180