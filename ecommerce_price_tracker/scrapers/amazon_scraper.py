from datetime import datetime
import random

def scrape_amazon():
    """
    Simulated Amazon scraper (ToS-safe).
    """
    products = [
        {
            "name": "Apple iPhone 15 (128GB)",
            "price": round(random.uniform(65000, 75000), 2),
            "rating": 4.5,
            "availability": "In Stock",
            "url": "https://www.amazon.in/dp/example1",
            "image_url": None,
            "site": "amazon",
            "scraped_at": datetime.utcnow()
        },
        {
            "name": "Samsung Galaxy S23",
            "price": round(random.uniform(55000, 65000), 2),
            "rating": 4.4,
            "availability": "In Stock",
            "url": "https://www.amazon.in/dp/example2",
            "image_url": None,
            "site": "amazon",
            "scraped_at": datetime.utcnow()
        }
    ]
    return products
