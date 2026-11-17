"""Print the structure of every sample bhavcopy file, so we can design parsers
around the real columns instead of guessing."""
from pathlib import Path

import pandas as pd

pd.set_option("display.max_columns", None)  # show every column, don't hide any with "..."
pd.set_option("display.width", 220)

SAMPLES = Path("data/raw/samples")
CATEGORY_COLUMNS = ["SERIES", "SctySrs", "INSTRUMENT", "FinInstrmTp", "OPTION_TYP", "OptnTp"]


def inspect(path: Path) -> None:
    df = pd.read_csv(path)                  # pandas unzips single-file zips automatically
    df.columns = df.columns.str.strip()     # old files have stray spaces in column names

    print("=" * 100)
    print(f"{path.name}:  {len(df):,} rows x {df.shape[1]} columns")
    print("\n--- Columns and their data types ---")
    print(df.dtypes.to_string())
    print("\n--- First 3 rows ---")
    print(df.head(3).to_string())

    for col in CATEGORY_COLUMNS:
        if col in df.columns:
            print(f"\n--- Most common values in '{col}' ---")
            print(df[col].value_counts().head(8).to_string())
    print()


if __name__ == "__main__":
    files = sorted(SAMPLES.glob("*.zip"))
    if not files:
        print(f"No .zip files found in {SAMPLES.resolve()}")
    for f in files:
        inspect(f)