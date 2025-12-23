import sys
import os
from datetime import datetime


sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from core.validator import generate_product_id

from scrapers.amazon_scraper import scrape_amazon
from scrapers.flipkart_scraper import scrape_flipkart
from scrapers.croma_scraper import scrape_croma
from scrapers.reliance_scraper import scrape_reliance
from scrapers.snapdeal_scraper import scrape_snapdeal

from core.db_manager import insert_prices
from core.logger import get_logger
from core.alerts import send_email

logger = get_logger("SCRAPER_MAIN")

SCRAPERS = [
    scrape_amazon,
    scrape_flipkart,
    scrape_croma,
    scrape_reliance,
    scrape_snapdeal
]

def run_all_scrapers():
    all_records = []
    failed_scrapers = []

    logger.info("Starting scheduled e-commerce scraping job")

    for scraper in SCRAPERS:
        try:
            records = scraper()
            for r in records:
                r["product_id"] = generate_product_id(r["name"])
            logger.info(f"{scraper.__name__}: {len(records)} records")
            all_records.extend(records)
        except Exception as e:
            logger.error(f"{scraper.__name__} failed: {e}")
            failed_scrapers.append(scraper.__name__)

    if all_records:
        insert_prices(all_records)
        logger.info(f"Inserted {len(all_records)} records into database")

    return len(all_records), failed_scrapers


if __name__ == "__main__":
    rows_inserted, failures = run_all_scrapers()

    # 🚨 ALERT CONDITIONS
    if rows_inserted == 0:
        send_email(
            subject="🚨 Price Tracker FAILED",
            message=(
                "No products were scraped.\n\n"
                f"Time: {datetime.utcnow()}\n"
                "Action required: Check scrapers."
            )
        )
        sys.exit(1)

    if failures:
        send_email(
            subject="⚠️ Partial Scraping Failure",
            message=(
                "Some scrapers failed:\n\n"
                f"{failures}\n\n"
                f"Time: {datetime.utcnow()}"
            )
        )

    logger.info("Scraping job completed successfully")
    sys.exit(1)
