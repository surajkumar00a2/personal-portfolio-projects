import requests
import json
import boto3
import time
from datetime import datetime

ALPHA_VANTAGE_KEY = "39F2724KEJPB9DQ0"
STOCK_SYMBOL = "IBM"
INTERVAL = "5min"

KINESIS_STREAM_NAME = "StockDataStream"
KINESIS_REGION_NAME = "us-east-1"

# Kinesis client
kinesis = boto3.client("kinesis", region_name=KINESIS_REGION_NAME)

def fetch_stcok_data():
    """Fetches stock data from Alpha Vantage"""
    url = f"https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol={STOCK_SYMBOL}&interval={INTERVAL}&apikey={ALPHA_VANTAGE_KEY}"
    response = requests.get(url)
    response.raise_for_status()
    return response.json()

def process_and_send(data):
    """Process the API response and send records to Kinesis"""
    time_series_key = f"Time Series ({INTERVAL})"
    time_series = data.get(time_series_key, {})
    
    if not time_series:
        print("No data received or API limit reached.")
        return

    for timestamp, values in sorted(time_series.items()):
        record = {
            "symbol": STOCK_SYMBOL,
            "timestamp": timestamp,
            "open": float(values["1. open"]),
            "high": float(values["2. high"]),
            "low": float(values["3. low"]),
            "close": float(values["4. close"]),
            "volume": int(values["5. volume"])
        }
        # Convert to JSON and send to Kinesis
        kinesis.put_record(
            StreamName=KINESIS_STREAM_NAME,
            Data=json.dumps(record),
            PartitionKey=STOCK_SYMBOL
        )
        print(f"[{datetime.utcnow().isoformat()}] Sent record for {timestamp}")

if __name__ == "__main__":
    while True:
        try:
            print(f"{datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} - Fetching stock data... {STOCK_SYMBOL}")
            raw_data = fetch_stcok_data()
            process_and_send(raw_data)
        except Exception as e:
            print(f"Error: {e}")
        time.sleep(60)