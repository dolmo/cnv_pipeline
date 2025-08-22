#This is the main file


import pandas as pd
import argparse
import os
import sys
import numpy as np
import plotly.express as px
import argparse
import pandas as pdx    

from filter_variants import filter_variants
from plot_variants import plot_chromosomes, plot_variant_type,plot_svlength




def main():
    #input/output
    parser = argparse.ArgumentParser(description="Full CNV Pipeline")
    parser.add_argument("-i", "--input_file", required=True, help="Input file containing annotated variants")
    parser.add_argument("-ov", "--output_variant_plot", default="variant_plot.png", help="Output image filename")
    parser.add_argument("-oc", "--output_chromosome_plot", default="chromosome_plot.png", help="Output image filename")
    parser.add_argument("-ol", "--output_variant_length_plot", default="variant_length_plot.png", help="Output image filename")



    



    args = parser.parse_args()
    filter_variants(args.input_file, "filtered_variants.tsv")
    df = pd.read_table("filtered_variants.tsv" ,sep='\t', comment='#', low_memory=False)


    if args.output_variant_plot is not None:

        plot_variant_type(args.output_variant_plot,df)
    else:
        print("No output file name/path has been inputted by user for chromosome plot")

    if args.output_chromosome_plot is not None:
        plot_chromosomes(args.output_chromosome_plot,df)
    else:
        print("No output file name/path has been inputted by user for chromosome plot")

    if args.output_variant_length_plot is not None:
        plot_svlength(args.output_variant_length_plot,df)
    else:
        print("No output file name/path has been inputted by user for chromosome plot")




if __name__ == "__main__":
    main()