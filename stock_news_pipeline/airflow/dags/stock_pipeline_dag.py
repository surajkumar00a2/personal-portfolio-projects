from airflow import DAG
from airflow.operators.python import PythonOperator # type: ignore
from datetime import datetime, timedelta
import pandas as pd
from src.stock_extractor import fetch_stock_prices
from src.news_scraper import scrape_news
from src.data_processor import clean_stock_data, quality_checks
from src.db_manager import insert_dataframe


default_args = {
    "owner": "suraj",
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="stock_news_pipeline",
    start_date=datetime(2024, 1, 1),
    schedule_interval="0 18 * * *",
    catchup=False,
    default_args=default_args,
) as dag:

    def normalize_columns(df):
        """
        Flattens MultiIndex columns from yfinance
        and converts all column names to lowercase.
        """
        if isinstance(df.columns, pd.MultiIndex):
            df.columns = [col[0] for col in df.columns]

        df.columns = [col.lower() for col in df.columns]
        return df

    def stock_task():
        df = fetch_stock_prices()
        df = clean_stock_data(df)
        df = normalize_columns(df)
        quality_checks(df)
        insert_dataframe(df, "stock_prices")

    def news_task():
        df = scrape_news()
        insert_dataframe(df, "stock_news")

    extract_stock = PythonOperator(
        task_id="extract_stock_data",
        python_callable=stock_task,
    )

    extract_news = PythonOperator(
        task_id="extract_news",
        python_callable=news_task,
    )

    extract_stock >> extract_news
