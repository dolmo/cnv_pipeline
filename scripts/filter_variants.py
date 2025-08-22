import pandas as pd
import argparse
import os
import sys
import numpy as np


def filter_variants(input_file, output_file):
    # Read the input file
    df = pd.read_table(input_file, sep='\t', comment='#', low_memory=False)


    # Filter variants based on passing the "FILTER" column
    # Assuming the "FILTER" column exists and contains values like "PASS"
    filtered_df = df[
        (df["FILTER"] == "PASS") &
        (df["SV_type"].isin(["DEL", "DUP"]))
    ]

    filtered_df = filtered_df.drop_duplicates(subset=['SV_length'])

    # Save the filtered variants to the output file
    filtered_df.to_csv(output_file, sep='\t', index=False)

    #print(f"Filtered variants saved to {output_file}")
