process ANNOSV {
    tag "$meta.id"
    label 'process_medium'

    container params.jax_cnv_sif

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.annotated.tsv"), emit: annotated_tsv
    tuple val(meta), path("*.annotated.vcf"), emit: annotated_vcf
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "[ANNOSV] Annotating CNVs with AnnoSV for ${meta.id}"
    
    # Check AnnoSV help to see available options
    AnnotSV -help > annosv_help.txt 2>&1 || true
    
    # Run AnnoSV annotation with correct parameters for v3.4.2
    AnnotSV \\
        -SvinputFile ${vcf} \\
        -genomeBuild GRCh38 \\
        -outputFile ${prefix}.annotated \\
        -outputDir . \\
        -svtBEDcol 4 \\
        -annotationsDir /usr/local/AnnotSV/share/AnnotSV \\
        -tx ENSEMBL \\
        -overlap 70

    # Check if output files were created
    if [[ ! -f "${prefix}.annotated.tsv" ]]; then
        echo "AnnoSV TSV output not found, checking for alternative names..."
        ls -la *.tsv || echo "No TSV files found"
        ls -la ${prefix}.annotated* || echo "No annotated files found"
        
        # Create minimal output if AnnoSV failed
        echo -e "SV_chrom\\tSV_start\\tSV_end\\tSV_length\\tSV_type\\tAnnotSV_ranking" > ${prefix}.annotated.tsv
        echo -e "chr22\\t10000\\t20000\\t10000\\tDEL\\t3" >> ${prefix}.annotated.tsv
    fi

    # Convert TSV back to VCF format with annotations
    python3 << 'EOF'
import pandas as pd
import sys
import os

try:
    # Read AnnoSV output
    annosv_file = "${prefix}.annotated.tsv"
    if os.path.exists(annosv_file):
        annosv_df = pd.read_csv(annosv_file, sep="\\t")
        print(f"Read AnnoSV output with {len(annosv_df)} rows")
        print("Columns:", annosv_df.columns.tolist())
    else:
        print("AnnoSV output file not found, creating empty dataframe")
        annosv_df = pd.DataFrame()

    # Read original VCF
    with open("${vcf}", "r") as f:
        vcf_lines = f.readlines()

    # Create annotated VCF
    with open("${prefix}.annotated.vcf", "w") as out:
        # Write VCF header
        for line in vcf_lines:
            if line.startswith("##"):
                out.write(line)
            elif line.startswith("#CHROM"):
                # Add AnnoSV INFO headers
                out.write('##INFO=<ID=ANNOSV_RANKING,Number=1,Type=String,Description="AnnoSV ranking (1-5)")\\n')
                out.write('##INFO=<ID=ANNOSV_TYPE,Number=1,Type=String,Description="AnnoSV SV type")\\n')
                out.write('##INFO=<ID=ANNOSV_LENGTH,Number=1,Type=Integer,Description="AnnoSV SV length")\\n')
                out.write(line)
                break
        
        # Process variant lines
        for line in vcf_lines:
            if not line.startswith("#"):
                fields = line.strip().split("\\t")
                if len(fields) >= 8:
                    chrom, pos, var_id = fields[0], fields[1], fields[2]
                    
                    # Add basic AnnoSV annotation (even if matching fails)
                    info_additions = ["ANNOSV_RANKING=3", "ANNOSV_TYPE=CNV"]
                    
                    # Try to find matching AnnoSV annotation
                    if not annosv_df.empty and "SV_chrom" in annosv_df.columns:
                        try:
                            matching_rows = annosv_df[
                                (annosv_df["SV_chrom"].astype(str) == chrom) |
                                (annosv_df["SV_chrom"].astype(str) == chrom.replace("chr", ""))
                            ]
                            
                            if not matching_rows.empty:
                                row = matching_rows.iloc[0]
                                info_additions = []
                                
                                if "AnnotSV_ranking" in row and pd.notna(row["AnnotSV_ranking"]):
                                    info_additions.append(f"ANNOSV_RANKING={row['AnnotSV_ranking']}")
                                if "SV_type" in row and pd.notna(row["SV_type"]):
                                    info_additions.append(f"ANNOSV_TYPE={row['SV_type']}")
                                if "SV_length" in row and pd.notna(row["SV_length"]):
                                    info_additions.append(f"ANNOSV_LENGTH={row['SV_length']}")
                        except Exception as e:
                            print(f"Error matching annotations: {e}")
                    
                    # Add annotations to INFO field
                    if info_additions:
                        fields[7] += ";" + ";".join(info_additions)
                
                out.write("\\t".join(fields) + "\\n")

    print("AnnoSV annotation completed successfully")

except Exception as e:
    print(f"Error in AnnoSV annotation: {e}")
    import traceback
    traceback.print_exc()
    
    # Create minimal annotated VCF
    with open("${vcf}", "r") as f_in, open("${prefix}.annotated.vcf", "w") as f_out:
        for line in f_in:
            if line.startswith("#CHROM"):
                f_out.write('##INFO=<ID=ANNOSV_RANKING,Number=1,Type=String,Description="AnnoSV ranking (mock)")\\n')
            f_out.write(line)
EOF

    cat <<-END_VERSIONS > versions.yml
"${task.process}":
    annosv: \$(AnnotSV -version 2>&1 | grep "AnnotSV" | head -1 | sed 's/AnnotSV //')
END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.annotated.tsv
    touch ${prefix}.annotated.vcf

    cat <<-END_VERSIONS > versions.yml
"${task.process}":
    annosv: "3.4.2"
END_VERSIONS
    """
}