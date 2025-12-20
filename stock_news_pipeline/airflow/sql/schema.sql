CREATE TABLE IF NOT EXISTS stock_prices (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(10),
    date DATE,
    open NUMERIC,
    high NUMERIC,
    low NUMERIC,
    close NUMERIC,
    volume BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stock_news (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(10),
    headline TEXT,
    url TEXT,
    published_date TIMESTAMP,
    scraped_at TIMESTAMP
);
