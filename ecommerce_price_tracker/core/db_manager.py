import psycopg2
from psycopg2.extras import execute_values
from core.config import POSTGRES_CONFIG

def get_connection():
    return psycopg2.connect(**POSTGRES_CONFIG)

def insert_prices(records):
    if not records:
        return

    query = """
    INSERT INTO prices (product_id, site, price, rating, availability, scraped_at, url)
    VALUES %s
    """

    values = [
        (
            r["product_id"], r["site"], r["price"],
            r["rating"], r["availability"], r["scraped_at"], r["url"]
        )
        for r in records
    ]

    conn = get_connection()
    cur = conn.cursor()
    execute_values(cur, query, values)
    conn.commit()
    cur.close()
    conn.close()
