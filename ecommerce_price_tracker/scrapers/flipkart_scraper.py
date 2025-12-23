from datetime import datetime
import random

def scrape_flipkart():
    """
    Simulated Flipkart scraper (ToS-safe).
    """
    products = [
        {
            "name": "Apple iPhone 15 (128GB)",
            "price": round(random.uniform(64000, 74000), 2),
            "rating": 4.6,
            "availability": "In Stock",
            "url": "https://www.flipkart.com/example1",
            "image_url": None,
            "site": "flipkart",
            "scraped_at": datetime.utcnow()
        },
        {
            "name": "Samsung Galaxy S23",
            "price": round(random.uniform(54000, 64000), 2),
            "rating": 4.5,
            "availability": "Limited Stock",
            "url": "https://www.flipkart.com/example2",
            "image_url": None,
            "site": "flipkart",
            "scraped_at": datetime.utcnow()
        }
    ]
    return products
