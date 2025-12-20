import yfinance as yf
import pandas as pd
from src.config import STOCK_SYMBOLS
from src.logger import get_logger

logger = get_logger(__name__)

def fetch_stock_prices():
    all_data = []

    for symbol in STOCK_SYMBOLS:
        logger.info(f"Fetching stock data for {symbol}")

        df = yf.download(
            symbol,
            period="1y",
            interval="1d",
            auto_adjust=False,
            progress=False
        )

        if df.empty:
            logger.warning(f"No data for {symbol}")
            continue

        df.reset_index(inplace=True)

        # 🔥 Flatten MultiIndex if present
        if isinstance(df.columns, pd.MultiIndex):
            df.columns = [c[0] for c in df.columns]

        # 🔥 Normalize column names
        df.columns = [c.lower() for c in df.columns]

        # 🔥 Add symbol
        df["symbol"] = symbol

        # 🔥 SAFE column selection
        required_cols = ["symbol", "date", "open", "high", "low", "close", "volume"]
        df = df[[c for c in required_cols if c in df.columns]]

        all_data.append(df)

    final_df = pd.concat(all_data, ignore_index=True)
    logger.info(f"Total stock rows fetched: {len(final_df)}")

    return final_df
