# This is the bed to vcf converter we are using to push through JAX CNV output to the variant benchmarking pipeline


import sys

def bed_to_vcf(bed_file, vcf):
    with open(bed_file) as bed, open(vcf, 'w') as vcf:
        vcf.write("##fileformat=VCFv4.2\n")
        vcf.write("##ALT=<ID=DEL,Description=\"Deletion\">\n")
        vcf.write("##ALT=<ID=DUP,Description=\"Duplication\">\n")
        vcf.write("##INFO=<ID=SVTYPE,Number=1,Type=String,Description=\"Type of structural variant\">\n")
        vcf.write("##INFO=<ID=END,Number=1,Type=Integer,Description=\"End position of the variant\">\n")
        vcf.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tSV_length\tFORMAT\n")

        for line in bed:
            fields = line.strip().split()
            if len(fields) < 4:
                continue  # Skip malformed lines
            chrom = fields[0]
            # Skip alternative contigs
            if any(x in chrom for x in ["_alt", "_random", "_decoy"]):
                continue
            start, end = int(fields[1]), int(fields[2])
            svtype = fields[3]
            alt = f"<{svtype}>"
            info = f"SVTYPE={svtype};END={end}"
            # Optionally add CN to INFO if present
            if len(fields) > 4:
                info += f";CN={fields[4]}"
            sv_length = end - start
            # Add FORMAT column with dot for AnnotSV compatibility
            vcf.write(f"{chrom}\t{start}\t.\tN\t{alt}\t.\t.\t{info}\t{sv_length}\t.\n")


def main():
    if len(sys.argv) != 3:
        print("Usage: python jaxcnv_bed_to_vcf.py input.bed output.vcf")
        sys.exit(1)
    
    bed_file = sys.argv[1]
    vcf_file = sys.argv[2]
    bed_to_vcf(bed_file, vcf_file)

if __name__ == "__main__":
    main()
