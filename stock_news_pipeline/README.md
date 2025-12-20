# Automated Stock & News Data Pipeline
**Author:** Suraj Kumar
A production-ready data engineering project that extracts stock price data and financial news from Yahoo Finance, processes and validates it using Pandas, stores it in PostgreSQL, and orchestrates the entire workflow using Apache Airflow.

This project is designed to be **simple, local, and portfolio-ready**, showcasing real-world ETL, orchestration, data quality checks, and monitoring.

---

## Architecture Overview

```
flowchart LR
    A[Yahoo Finance] --> B[Stock & News Extractors]
    B --> C[Pandas Transformations]
    C --> D[Data Quality Checks]
    D --> E[PostgreSQL]
    E --> F[Apache Airflow DAG]
```

## Tech Stack.

- Python (Pandas, Requests, BeautifulSoup)
- Yahoo Finance API (yfinance)
- PostgreSQL
- Apache Airflow (Dockerized)
- Docker & Docker Compose

## Project Structure

```
stock_news_pipeline/
└── airflow/
    ├── dags/
    │   └── stock_pipeline_dag.py
    ├── src/
    │   ├── __init__.py
    │   ├── stock_extractor.py
    │   ├── news_scraper.py
    │   ├── data_processor.py
    │   ├── db_manager.py
    │   ├── config.py
    │   └── logger.py
    ├── sql/
    │   └── schema.sql
    ├── Dockerfile
    ├── docker-compose.yml
    ├── requirements.txt
    ├── .env.example
    └── .env   ❌ (ignored by git)
├── README.md
├── .gitignore
```

## Pipeline Workflow

- Extract historical stock prices using yfinance
- Scrape financial news from Yahoo Finance
- Clean and validate data using Pandas
- Run data quality checks (nulls, duplicates, row counts)
- Load processed data into PostgreSQL
- Orchestrate and monitor using Apache Airflow

## Scheduling & Reliability

- Runs daily at 6:00 PM IST
- Automatic retries (3 attempts, 5-minute delay)
- Centralized logging visible in Airflow UI
- Failure handling with task-level isolation

## How to Run Locally
```docker-compose up -d```
Access Airflow UI:
```http://localhost:8080```
Login:
```
username: airflow
password: airflow
```
Trigger DAG manually:
```
airflow dags trigger stock_news_pipeline
```

## Data Stored
Tables

```stock_prices```
- OHLCV historical stock price data
- ~2,500+ rows per run
```stock_news```
- Financial news headlines via RSS
- ~100+ records per run

## Output Validation

Example checks:
```
SELECT COUNT(*) FROM stock_prices;
SELECT COUNT(*) FROM stock_news;
```
```
SELECT symbol, date, close 
FROM stock_prices 
ORDER BY date DESC 
LIMIT 5;
```
## License

MIT License


> This project focuses on reliability, observability, and real-world failure handling rather than toy examples.
