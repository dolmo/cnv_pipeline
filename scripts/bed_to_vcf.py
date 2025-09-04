import sys

#!/usr/bin/env python3


def bed_to_vcf(bed_file, vcf_file):
    with open(bed_file) as bed, open(vcf_file, 'w') as vcf:
        # Write VCF header
        vcf.write("##fileformat=VCFv4.2\n")
        vcf.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n")
        for line in bed:
            if line.startswith('#') or not line.strip():
                continue
            fields = line.strip().split('\t')
            chrom = fields[0]
            start = int(fields[1]) + 1  # VCF is 1-based
            end = fields[2]
            vid = fields[3] if len(fields) > 3 else '.'
            ref = 'N'
            alt = '<DEL>'
            qual = '.'
            filt = 'PASS'
            info = f"END={end}"
            vcf.write(f"{chrom}\t{start}\t{vid}\t{ref}\t{alt}\t{qual}\t{filt}\t{info}\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} input.bed output.vcf")
        sys.exit(1)
    bed_to_vcf(sys.argv[1], sys.argv[2])