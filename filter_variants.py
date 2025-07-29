import pandas as pd
import argparse
import os
import sys
import numpy as np
import matplotlib.pyplot as plt


def filter_variants(input_file, output_file):
    # Read the input file
    df = pd.read_table(input_file, sep='\t', comment='#', low_memory=False)

    print(df.head())

    # Filter variants based on passing the "FILTER" column
    # Assuming the "FILTER" column exists and contains values like "PASS"
    filtered_df = df[
    (df["FILTER"] == "PASS") &
    (df["DP"] >= 10) &
    (df["AF"] >= 0.2) & (df["AF"] <= 0.8) &
    (df["Effect"].isin(["missense_variant", "frameshift_variant", "stop_gained"])) &
    (df["CADD"] >= 15)
]


    # Save the filtered variants to the output file
    filtered_df.to_csv(output_file, sep='\t', index=False)

    #print(f"Filtered variants saved to {output_file}")



def main():
    parser = argparse.ArgumentParser(description="Filter variants")
    parser.add_argument("-i", "--input_file", required=True, help="Input file containing annotated variants")
    parser.add_argument("-o", "--output_file", required=True, help="Output file to save filtered variants")
    
    args = parser.parse_args()

    if not os.path.exists(args.input_file):
        print(f"Error: Input file {args.input_file} does not exist.")
        sys.exit(1)

    filter_variants(args.input_file, args.output_file)

if __name__ == "__main__":
    main()
    