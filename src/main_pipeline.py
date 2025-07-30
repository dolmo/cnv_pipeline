#This is the main file


import pandas as pd
import argparse
import os
import sys
import numpy as np
import plotly.express as px
import argparse
import pandas as pd

from filter_variants import filter_variants
from plot_variants import plot_variants




def main():
    #input/output
    parser = argparse.ArgumentParser(description="Full CNV Pipeline")
    parser.add_argument("-i", "--input_file", required=True, help="Input file containing annotated variants")
    parser.add_argument("-o", "--output_plot", default="variant_plot.png", help="Output image filename")
    



    args = parser.parse_args()

    plot_variants(args.input_file,args.output_plot)




if __name__ == "__main__":
    main()