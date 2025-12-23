import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import requests
from bs4 import BeautifulSoup
from datetime import datetime
from core.validator import clean_price, validate_product

HEADERS = {"User-Agent": "Mozilla/5.0"}

def scrape_croma():
    url = "https://www.croma.com/searchB?q=laptop"
    r = requests.get(url, headers=HEADERS, timeout=10)
    soup = BeautifulSoup(r.text, "html.parser")

    results = []

    for item in soup.select("div.product-item"):
        name_tag = item.select_one("h3.product-title")
        price_tag = item.select_one("span.amount")

        if not name_tag or not price_tag:
            continue

        product = {
            "name": name_tag.text.strip(),
            "price": clean_price(price_tag.text),
            "rating": None,
            "availability": "In Stock",
            "url": "https://www.croma.com" + item.a["href"],
            "image_url": None,
            "site": "croma",
            "scraped_at": datetime.utcnow()
        }

        if validate_product(product):
            results.append(product)

    return results


results = scrape_croma()
print(results)