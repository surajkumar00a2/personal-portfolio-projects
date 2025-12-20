import feedparser
import pandas as pd
from datetime import datetime
from src.config import STOCK_SYMBOLS
from src.logger import get_logger

logger = get_logger(__name__)

def scrape_news():
    all_news = []

    for symbol in STOCK_SYMBOLS:
        rss_url = f"https://finance.yahoo.com/rss/headline?s={symbol}"
        logger.info(f"Fetching RSS news for {symbol}")

        feed = feedparser.parse(rss_url)

        for entry in feed.entries:
            all_news.append({
                "symbol": symbol,
                "headline": entry.title,
                "url": entry.link,
                "published_date": entry.get("published", None),
                "scraped_at": datetime.utcnow()
            })

    df = pd.DataFrame(all_news)
    logger.info(f"Total news records scraped: {len(df)}")
    return df
