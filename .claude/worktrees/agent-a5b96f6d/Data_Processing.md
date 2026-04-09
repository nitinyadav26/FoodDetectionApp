
# Data Processing & Sources

## Overview
The application relies on a comprehensive database of Indian foods to enable accurate manual logging. This data is derived from the **Indian Nutrient Databank (INDB)** and processed into a mobile-friendly JSON format.

## Data Sources
The primary source is the **INDB** project, which aggregates data from:
1.  **ICMR-NIN IFCT (2017 & 2004)**: Premier source for Indian food composition.
2.  **UK & US Databases**: Supplement data for ingredients not found in Indian tables.
3.  **Standard Recipes**: Nutrient values calculated for 1,014 common recipes based on standard preparation methods.

*For full scientific credits and methodology, please refer to the original `INDB_data/README.md`.*

---

## Processing Pipeline

The goal of the processing pipeline is to convert the raw scientific Excel data into a lightweight JSON file that the iOS app can load quickly.

### Script: `convert_indb.py`
This Python script performs the following operations:

1.  **Ingestion**: Reads the `INDB.xlsx` master file using `pandas`.
2.  **Deduplication**: Removes duplicate food codes to ensure unique identifiable entries.
3.  **Serving Size Calculation**:
    *   The raw data provides calories per 100g (`energy_kcal`) and calories per serving unit (`unit_serving_energy_kcal`).
    *   The script calculates the **weight of a standard serving** using the formula:
        ```python
        weight_g = (kcal_per_serving / kcal_per_100g) * 100
        ```
    *   This allows the app to let users select "1 Bowl" or "1 Piece" and accurately calculate nutrition.
4.  **Normalization**: Rounds values to 1 decimal place and handles missing data (NaNs).
5.  **Output**: Generates `indb_foods.json`.

### Output Format (`indb_foods.json`)
The resulting JSON file is an array of food objects structured as follows:

```json
[
  {
    "id": "ASC-001",
    "name": "Aloo Gobi",
    "base_calories_per_100g": 120.5,
    "base_protein_per_100g": 3.2,
    "base_carbs_per_100g": 15.1,
    "base_fat_per_100g": 5.4,
    "servings": [
      {
        "label": "1 bowl",
        "weight": 250.0
      }
    ]
  }
]
```

## Updating the Database
To update the app's food database with new scientific data:
1.  Place the updated `INDB.xlsx` in the `INDB_data/` folder.
2.  Run the conversion script:
    ```bash
    cd INDB_data
    python3 convert_indb.py
    ```
3.  Copy the generated `indb_foods.json` to the main app bundle:
    ```bash
    cp indb_foods.json ../FoodDetectionApp/
    ```
4.  Rebuild the iOS app.
