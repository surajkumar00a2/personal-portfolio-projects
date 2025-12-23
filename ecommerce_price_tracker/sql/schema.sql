CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name TEXT,
    category TEXT,
    first_seen TIMESTAMP,
    last_updated TIMESTAMP
);

CREATE TABLE prices (
    id SERIAL PRIMARY KEY,
    product_id TEXT,
    site TEXT,
    price NUMERIC,
    rating NUMERIC,
    availability TEXT,
    scraped_at TIMESTAMP,
    url TEXT
);
