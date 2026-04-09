import pandas as pd
import json
import numpy as np

def convert():
    print("Loading Excel files...")
    indb = pd.read_excel('INDB.xlsx')
    # recipes_servingsize might be useful for extra metadata, but INDB seems to have the unit and separate unit_energy
    # Let's inspect if we need recipes_servingsize for anything missing in INDB
    # Indb has 'servings_unit' and 'unit_serving_energy_kcal'. This looks self-contained for the calculation.
    
    # Filter for unique food codes just in case
    indb = indb.drop_duplicates(subset=['food_code'])
    
    output = []
    
    print(f"Processing {len(indb)} records...")
    
    for _, row in indb.iterrows():
        try:
            code = row['food_code']
            name = row['food_name']
            cal_100 = row['energy_kcal']
            prot_100 = row['protein_g']
            carb_100 = row['carb_g']
            fat_100 = row['fat_g']
            
            # Unit serving info
            u_cal = row['unit_serving_energy_kcal']
            u_unit = row['servings_unit']
            
            servings_list = []
            
            # Calculate weight of the unit serving
            # weight_g = (kcal_per_serving / kcal_per_100g) * 100
            weight = 0
            if pd.notnull(cal_100) and cal_100 > 0 and pd.notnull(u_cal):
                weight = (u_cal / cal_100) * 100
            
            # Only add if weight is reasonable
            if weight > 0:
                label = u_unit if pd.notnull(u_unit) else "Standard Serving"
                servings_list.append({
                    "label": str(label),
                    "weight": round(weight, 1)
                })
            
            # Construct item
            item = {
                "id": str(code),
                "name": str(name).strip(),
                "base_calories_per_100g": round(cal_100, 1) if pd.notnull(cal_100) else 0,
                "base_protein_per_100g": round(prot_100, 1) if pd.notnull(prot_100) else 0,
                "base_carbs_per_100g": round(carb_100, 1) if pd.notnull(carb_100) else 0,
                "base_fat_per_100g": round(fat_100, 1) if pd.notnull(fat_100) else 0,
                "servings": servings_list
            }
            output.append(item)
            
        except Exception as e:
            print(f"Skipping row {row.get('food_code', 'unknown')}: {e}")
            
    # Save
    out_path = 'indb_foods.json'
    with open(out_path, 'w') as f:
        json.dump(output, f, indent=2)
    
    print(f"Conversion complete. Saved to {out_path} with {len(output)} items.")

if __name__ == '__main__':
    convert()
