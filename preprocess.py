import pandas as pd
import numpy as np
import kagglehub
import os

DATA_SET_PATH = (
    kagglehub.dataset_download("abhinavshaw09/food-prices-in-india")
    + "/food_prices_ind.csv"
)

df = pd.read_csv(DATA_SET_PATH)

# Handle missing value
df.dropna(subset=["price", "state", "commodity"], inplace=True)
df["date"] = pd.to_datetime(df["date"])
df["price"] = pd.to_numeric(df["price"], errors="coerce")

# Feature extraction
df["year"] = df["date"].dt.year
df["month"] = df["date"].dt.month
df["season"] = pd.cut(
    df["month"], bins=[0, 3, 6, 9, 12], labels=["Winter", "Summer", "Monsoon", "Autumn"]
)

# Remove Outliers (3 standard deviations)
price_mean = df["price"].mean()
price_std = df["price"].std()
df = df[np.abs(df["price"] - price_mean) <= (3 * price_std)]

# Standardize State and City Names
df["state"] = df["state"].str.strip().str.title()
df["city"] = df["city"].str.strip().str.title()

df.head()

# Save the cleaned data to be loaded into HDFS
df.to_csv("food_prices_cleaned.csv", index=False)
