import pandas as pd
from src.logger import get_logger

logger = get_logger(__name__)

def normalize_columns(df):
    if isinstance(df.columns, pd.MultiIndex):
        df.columns = [col[0] for col in df.columns]

    df.columns = [col.lower() for col in df.columns]
    return df

def clean_stock_data(df: pd.DataFrame) -> pd.DataFrame:
    logger.info("Cleaning stock data")
    df = df.drop_duplicates()
    df = df.dropna()
    if "date" in df.columns:
        df["date"] = pd.to_datetime(df["date"])
    return df

def quality_checks(df: pd.DataFrame) -> dict:
    logger.info("Running data quality checks")

    metrics = {
        "row_count": len(df),
        "null_percentage": df.isnull().mean().round(4).to_dict(),
        "duplicate_rows": df.duplicated().sum()
    }

    logger.info(f"Data Quality Metrics: {metrics}")
    return metrics
