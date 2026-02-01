"""
Basic ingestion wihtout data quality monitoring
"""
import json
import boto3
import requests
import os
from datetime import datetime, timezone

# Configuration

S3_BUCKET = os.environ['S3_BUCKET']
API_KEY = os.environ['OPENWEATHER_API_KEY']
CITIES = ['London', 'Delhi', 'Tokyo', 'Dubai', 'Riyadh', 'Muscat']

s3 = boto3.client('s3')

def fetch_weather_data(city:str)->dict:
    '''
    :param city: Description
    :type city: str
    :return: Description
    :rtype: dict
    '''
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        'q':city,
        'appid':API_KEY,
        'units':"metric"
    }
    print(f"Fetching weather data for {city}...")
    try:
        response = requests.get(url,params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        return data
    except requests.exceptions.RequestException as e:
        print(f"Failed to fetch the data for {city}:{e}")

def write_to_bronze(city:str, data:dict)->bool:
    '''
    :param city: Description
    :type city: str
    :param data: Description
    :type data: dict
    :return: Description
    :rtype: bool
    '''
    now = datetime.now(timezone.utc)

    S3_key = (
        f"data/bronze/"
        f"date={now.strftime('%Y-%m-%d')}/"
        f"hour={now.strftime('%H')}/"
        f"{city.lower().replace(' ','_')}_weather_{now.strftime('%Y%m%d_%H%M%S')}.json"
    )
    payload = {
        "ingestion_metadata":{
            "ingestion_tiomestamp":now.isoformat(),
            "city":city,
            "source": "openweathermap"
        },
        "raw_data":data
    }

    try:
        s3.put_object(
            Bucket = S3_BUCKET,
            Key = S3_key,
            Body = json.dumps(payload, indent=2),
            ContentType = 'application/json'

        )
        print(f"Wrote to S3:{S3_key}")
        return True
    except Exception as e:
        print(f"S3 write failed: {e}")
        return False

def lambda_handler(event, context):
    '''
    :param event: Description
    :param context: Description
    '''
    print("-"*80)
    print(f"Weather Ingestion Started:{datetime.now(timezone.utc).isoformat()}")
    print("-"*80)

    results = []

    for city in CITIES:
        print(f"\n Processing: {city}")

        data = fetch_weather_data(city)
        if not data:
            results.append({
                'city':city, 'status':'failed', 'reason':'API error'
            })
            continue
        if write_to_bronze(city, data):
            results.append({
                'city':city, 'status':'success'
            })
        else:
            results.append({
                'city':city, 'status':'failed', 'error':'S3 error'
            })
    successful = len([r for r in results if r['status'] == 'success'])
    print("\n"+"-"*80)
    print(f"Summary:{successful}/{len(CITIES)} cities processed successfully")
    print("-"*80)

    return {
        'statusCode':200 if successful > 0 else 500,
        'body': json.dumps({
            'results':results,
            'total':len(CITIES),
            'successful':successful
        })
    }
