import re
import hashlib

def generate_product_id(name: str) -> str:
    """
    Generates a stable product ID using product name.
    """
    return hashlib.md5(name.lower().encode()).hexdigest()

def clean_price(price):
    if price is None:
        return None
    price = re.sub(r"[^\d.]", "", price)
    return float(price) if price else None

def validate_product(product):
    return (
        product.get("name") and
        isinstance(product.get("price"), (int, float)) and
        product.get("url", "").startswith("http")
    )
