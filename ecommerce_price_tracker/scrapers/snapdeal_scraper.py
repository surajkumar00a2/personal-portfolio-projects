from bs4 import BeautifulSoup
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import time
import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from core.validator import clean_price, validate_product

def scrape_snapdeal():
    url = "https://www.snapdeal.com/search?keyword=laptop"

    # 1️⃣ Selenium setup (headless)
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")

    driver = webdriver.Chrome(options=chrome_options)
    driver.get(url)
    time.sleep(5)  # allow JS to load

    soup = BeautifulSoup(driver.page_source, "html.parser")
    driver.quit()

    results = []

    # 2️⃣ Product sections (we confirmed this works)
    sections = soup.select("section.js-section.clearfix.dp-widget.dp-fired")

    for section in sections:
        items = section.find_all(
            "div", class_="product-tuple-listing", recursive=False
        )

        for item in items:
            name_tag = item.find("p", class_="product-title")
            price_tag = item.find("span", class_="product-price")
            url_tag = item.find("a", class_="dp-widget-link")
            # image_tag = item.find("img", class_="product-image")

            if not name_tag or not price_tag or not url_tag:
                continue

            product = {
                "name": name_tag.text.strip(),
                "price": clean_price(price_tag.text),
                "availability": "In Stock",
                "url": url_tag["href"],
                # "image_url": image_tag["src"] if image_tag else None,
                "site": "snapdeal",
                "scraped_at": datetime.utcnow()
            }

            if validate_product(product):
                results.append(product)

    return results

# For self check
# if __name__ == "__main__":
#     products = scrape_snapdeal()
#     for product in products:
#         print(product)