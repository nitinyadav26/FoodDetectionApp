import pandas as pd
import os

files = ['INDB.xlsx', 'recipes.xlsx', 'recipes_servingsize.xlsx']

for f in files:
    print(f"--- {f} ---")
    try:
        df = pd.read_excel(f, nrows=5)
        print(df.columns.tolist())
    except Exception as e:
        print(f"Error reading {f}: {e}")
    print("\n")
