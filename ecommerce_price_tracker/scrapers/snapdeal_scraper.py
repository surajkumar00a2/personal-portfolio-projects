import requests
from bs4 import BeautifulSoup
from datetime import datetime
from core.validator import clean_price, validate_product

HEADERS = {"User-Agent": "Mozilla/5.0"}

def scrape_snapdeal():
    url = "https://www.snapdeal.com/search?keyword=laptop"
    r = requests.get(url, headers=HEADERS, timeout=10)
    soup = BeautifulSoup(r.text, "html.parser")

    results = []

    for item in soup.select("div.product-tuple"):
        name_tag = item.select_one("p.product-title")
        price_tag = item.select_one("span.product-price")

        if not name_tag or not price_tag:
            continue

        product = {
            "name": name_tag.text.strip(),
            "price": clean_price(price_tag.text),
            "rating": None,
            "availability": "In Stock",
            "url": item.a["href"],
            "image_url": None,
            "site": "snapdeal",
            "scraped_at": datetime.utcnow()
        }

        if validate_product(product):
            results.append(product)

    return results
