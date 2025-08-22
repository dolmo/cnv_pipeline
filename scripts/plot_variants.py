# This plots the variants

import plotly.express as px
import argparse
import pandas as pd
import numpy as np



def plot_variant_type(output_variants_file,df):

    # parsing the structural variants and their types
    type_counts = df["SV_type"].value_counts().reset_index()
    # calling the total counts of each type
    type_counts.columns = ["Variant_Type", "Count"]

    # creating a bar graph with the count of deletions and duplications
    variant_type_plot = px.bar(
        type_counts,
        x="Variant_Type",
        y="Count",
        color="Variant_Type",
        title="Number of Genetic Variants by Type",
        labels={"Variant_Type": "Type", "Count": "Number of Variants"}
    )

    #displaying html file of the graph

    variant_type_plot.write_image(output_variants_file)  
    variant_type_plot.show()


def plot_chromosomes(output_chromosome_file,df):


    chromosome_plot_counts = df['SV_chrom'].value_counts().reset_index()

    chromosome_plot_counts.columns = ["Chromosome", "Count"]

    chrom_order = [str(i) for i in range(1, 23)] + ['X', 'Y']


    chromosome_pie_plot = px.pie(chromosome_plot_counts,
                                  values='Count', 
                                  names='Chromosome', 
                                  category_orders={'Chromosome': chrom_order}, 
                                  title='Variants per Chromosome')

    chromosome_pie_plot.write_image(output_chromosome_file)  

    chromosome_pie_plot.show()     




def plot_svlength(output_svlength_file, df):


    sv_lengths = pd.to_numeric(df['SV_length'], errors='coerce').dropna().abs()
    sv_lengths = sv_lengths[sv_lengths < 10000000] 


    svlength_plot = px.histogram(
        x=sv_lengths,
        nbins=50,
        title='Distribution of SV Lengths',
        labels={'x': 'SV Length (bp)', 'y': 'Count'},
    )


    svlength_plot.write_image(output_svlength_file)
    svlength_plot.show()







