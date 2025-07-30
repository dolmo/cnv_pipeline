# This plots the variants

import plotly.express as px
import argparse
import pandas as pd





def plot_variants(input_file,output_file):



    df = pd.read_table(input_file, sep='\t', comment='#', low_memory=False)

    # parsing the structural variants and their types
    type_counts = df["SV_type"].value_counts().reset_index()
    # calling the total counts of each type
    type_counts.columns = ["Variant_Type", "Count"]

    # creating a bar graph with the count of deletions and duplications
    fig = px.bar(
        type_counts,
        x="Variant_Type",
        y="Count",
        color="Variant_Type",
        title="Number of Genetic Variants by Type",
        labels={"Variant_Type": "Type", "Count": "Number of Variants"}
    )

    #displaying html file of the graph

    fig.write_image(output_file)  
    fig.show()
    

