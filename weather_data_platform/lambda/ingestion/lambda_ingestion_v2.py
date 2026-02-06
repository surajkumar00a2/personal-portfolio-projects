"""
Weather Data Ingestion Lambda - Version 2.1
WITH Quality Monitoring and Parquet Metrics
"""

import json
import boto3
import requests
import os
import pandas as pd
from io import BytesIO
from datetime import datetime, timezone
from quality_validator import validate_data, calculate_schema_fingerprint

# Configuration
S3_BUCKET = os.environ['S3_BUCKET']
API_KEY = os.environ['OPENWEATHER_API_KEY']
CITIES = ['London', 'Delhi', 'Tokyo', 'Dubai', 'Riyadh', 'Muscat']

# AWS clients
s3 = boto3.client('s3')
cloudwatch = boto3.client('cloudwatch')


def get_previous_schema_version(city: str) -> str:
    """
    Retrieve last known schema version for drift detection
    
    Args:
        city: City name to look up previous schema for
    
    Returns:
        Previous schema version hash, or None if not found
    """
    try:
        prefix = f"metrics/quality/"
        response = s3.list_objects_v2(
            Bucket=S3_BUCKET,
            Prefix=prefix,
            MaxKeys=20
        )
        
        if 'Contents' not in response:
            return None
        
        # Sort by last modified (most recent first)
        sorted_objects = sorted(
            response['Contents'], 
            key=lambda x: x['LastModified'], 
            reverse=True
        )
        
        # Find most recent metrics for this city
        city_safe = city.lower().replace(' ', '_')
        for obj in sorted_objects:
            if city_safe in obj['Key'].lower() and obj['Key'].endswith('.parquet'):
                try:
                    # For Parquet files, we'd need to read them
                    # For now, return None to avoid complexity
                    # In production, you'd use pyarrow to read the schema_version
                    pass
                except:
                    continue
        
        return None
    except Exception as e:
        print(f"Could not retrieve previous schema: {e}")
        return None


def fetch_weather_data(city: str) -> tuple:
    """
    Fetch weather data with timing and error handling
    
    Returns:
        (data, http_status, latency_ms)
    """
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "q": city,
        "appid": API_KEY,
        "units": "metric"
    }
    
    print(f"📡 Fetching weather data for {city}...")
    start_time = datetime.now(timezone.utc)
    
    try:
        response = requests.get(url, params=params, timeout=10)
        latency_ms = int((datetime.now(timezone.utc) - start_time).total_seconds() * 1000)
        
        if response.status_code == 200:
            print(f"Success ({latency_ms}ms)")
            return response.json(), 200, latency_ms
        else:
            print(f"API Error: {response.status_code}")
            return None, response.status_code, latency_ms
            
    except requests.exceptions.Timeout:
        latency_ms = int((datetime.now(timezone.utc) - start_time).total_seconds() * 1000)
        print(f"   Timeout after {latency_ms}ms")
        return None, 0, latency_ms
    except requests.exceptions.RequestException as e:
        latency_ms = int((datetime.now(timezone.utc) - start_time).total_seconds() * 1000)
        print(f"   Request failed: {e}")
        return None, 0, latency_ms


def write_to_s3(city: str, data: dict, quality_metrics: dict) -> bool:
    """
    Write both raw data and quality metrics to S3
    
    Two writes:
    1. data/bronze/ - Raw API response (JSON)
    2. metrics/quality/ - Quality validation results (PARQUET)
    
    Returns:
        True if both writes successful, False otherwise
    """
    now = datetime.now(timezone.utc)
    date_str = now.strftime('%Y-%m-%d')
    hour_str = now.strftime('%H')
    timestamp_str = now.strftime('%Y%m%d_%H%M%S')
    city_safe = city.lower().replace(' ', '_')
    
    # ===== WRITE 1: Raw data to Bronze layer (JSON) =====
    data_key = (
        f"data/bronze/"
        f"date={date_str}/"
        f"hour={hour_str}/"
        f"{city_safe}_weather_{timestamp_str}.json"
    )
    
    data_payload = {
        "ingestion_metadata": {
            "ingestion_timestamp": now.isoformat(),
            "city": city,
            "source": "openweathermap",
            "schema_version": quality_metrics['schema_version']
        },
        "raw_data": data
    }
    
    try:
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=data_key,
            Body=json.dumps(data_payload, indent=2),
            ContentType='application/json'
        )
        print(f"  Data → s3://{S3_BUCKET}/{data_key}")
    except Exception as e:
        print(f"   Data write failed: {e}")
        return False
    
    # ===== WRITE 2: Quality metrics (PARQUET) =====
    metrics_key = (
        f"metrics/quality/"
        f"date={date_str}/"
        f"hour={hour_str}/"
        f"{city_safe}_metrics_{timestamp_str}.parquet"
    )
    
    # Flatten metrics structure for Parquet
    metrics_flat = {
        "city": city,
        "ingestion_timestamp": now,
        "validation_timestamp": datetime.fromisoformat(quality_metrics['validation_timestamp']),
        "schema_version": quality_metrics['schema_version'],
        
        # Field validation metrics
        "total_fields": quality_metrics['field_validation']['total_fields'],
        "populated_fields": quality_metrics['field_validation']['populated_fields'],
        "missing_fields": str(quality_metrics['field_validation']['missing_fields']),  # Array as string
        "missing_count": quality_metrics['field_validation']['missing_count'],
        "missing_percent": quality_metrics['field_validation']['missing_percent'],
        
        # Type validation metrics
        "type_errors": str(quality_metrics['type_validation']['errors']),  # Array as string
        "type_error_count": quality_metrics['type_validation']['error_count'],
        
        # Range validation metrics
        "range_errors": str(quality_metrics['range_validation']['errors']),  # Array as string
        "range_error_count": quality_metrics['range_validation']['error_count'],
        
        # Quality scores
        "completeness_score": quality_metrics['quality_scores']['completeness_score'],
        "consistency_score": quality_metrics['quality_scores']['consistency_score'],
        "timeliness_score": quality_metrics['quality_scores']['timeliness_score'],
        "availability_score": quality_metrics['quality_scores']['availability_score'],
        "overall_quality_score": quality_metrics['quality_scores']['overall_quality_score'],
        
        # Flags
        "has_issues": quality_metrics['has_issues'],
        "schema_drift_detected": quality_metrics.get('schema_drift_detected', False)
    }
    
    try:
        # Create DataFrame with single row
        df = pd.DataFrame([metrics_flat])
        
        # Convert to Parquet in memory
        parquet_buffer = BytesIO()
        df.to_parquet(
            parquet_buffer,
            engine='pyarrow',
            compression='snappy',
            index=False
        )
        
        # Upload to S3
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=metrics_key,
            Body=parquet_buffer.getvalue(),
            ContentType='application/octet-stream'
        )
        print(f"   Metrics (Parquet) → s3://{S3_BUCKET}/{metrics_key}")
    except Exception as e:
        print(f"   Metrics write failed: {e}")
        print(f"      Error details: {str(e)}")
        return False
    
    return True


def send_cloudwatch_metrics(
    city: str, 
    quality_scores: dict, 
    latency_ms: int, 
    missing_percent: float,
    schema_changed: bool
):
    """
    Send custom metrics to CloudWatch
    
    Metrics sent:
    - RecordsIngested (count)
    - OverallQualityScore (0-100)
    - CompletenessScore (0-100)
    - ConsistencyScore (0-100)
    - APILatency (milliseconds)
    - MissingFieldsPercent (%)
    - SchemaChanges (0 or 1)
    """
    namespace = 'DataPlatform/Quality'
    timestamp = datetime.now(timezone.utc)
    
    metrics = [
        {
            'MetricName': 'RecordsIngested',
            'Value': 1,
            'Unit': 'Count',
            'Timestamp': timestamp,
            'Dimensions': [{'Name': 'City', 'Value': city}]
        },
        {
            'MetricName': 'OverallQualityScore',
            'Value': quality_scores['overall_quality_score'],
            'Unit': 'None',
            'Timestamp': timestamp,
            'Dimensions': [{'Name': 'City', 'Value': city}]
        },
        {
            'MetricName': 'CompletenessScore',
            'Value': quality_scores['completeness_score'],
            'Unit': 'None',
            'Timestamp': timestamp,
            'Dimensions': [{'Name': 'City', 'Value': city}]
        },
        {
            'MetricName': 'ConsistencyScore',
            'Value': quality_scores['consistency_score'],
            'Unit': 'None',
            'Timestamp': timestamp,
            'Dimensions': [{'Name': 'City', 'Value': city}]
        },
        {
            'MetricName': 'APILatency',
            'Value': latency_ms,
            'Unit': 'Milliseconds',
            'Timestamp': timestamp,
            'Dimensions': [{'Name': 'City', 'Value': city}]
        },
        {
            'MetricName': 'MissingFieldsPercent',
            'Value': missing_percent,
            'Unit': 'Percent',
            'Timestamp': timestamp,
            'Dimensions': [{'Name': 'City', 'Value': city}]
        },
        {
            'MetricName': 'SchemaChanges',
            'Value': 1 if schema_changed else 0,
            'Unit': 'Count',
            'Timestamp': timestamp,
            'Dimensions': [{'Name': 'City', 'Value': city}]
        }
    ]
    
    try:
        cloudwatch.put_metric_data(
            Namespace=namespace,
            MetricData=metrics
        )
        print(f"   Sent {len(metrics)} metrics to CloudWatch")
    except Exception as e:
        print(f"   CloudWatch metrics failed: {e}")


def lambda_handler(event, context):
    """
    Main Lambda handler with quality monitoring
    
    Flow:
    1. Determine scheduled time
    2. For each city:
       a. Fetch data from API
       b. Validate data quality
       c. Check for schema drift
       d. Write data (JSON) + metrics (PARQUET) to S3
       e. Send CloudWatch metrics
    3. Return summary
    """
    print("=" * 80)
    print(f"WEATHER INGESTION WITH QUALITY MONITORING (Parquet Metrics)")
    print(f"   Started: {datetime.now(timezone.utc).isoformat()}")
    print("=" * 80)
    
    # Determine scheduled time (from EventBridge or calculated)
    if 'time' in event:
        scheduled_time = datetime.fromisoformat(event['time'].replace('Z', '+00:00'))
    else:
        # Calculate expected time (nearest 6-hour interval)
        now = datetime.now(timezone.utc)
        hour = (now.hour // 6) * 6
        scheduled_time = now.replace(hour=hour, minute=0, second=0, microsecond=0)
    
    print(f"Scheduled time: {scheduled_time.isoformat()}")
    print("")
    
    results = []
    
    for city in CITIES:
        print(f"{'─'*80}")
        print(f"PROCESSING: {city}")
        print(f"{'─'*80}")
        
        # Fetch data from API
        data, http_status, latency_ms = fetch_weather_data(city)
        
        if not data:
            print(f"   Skipping {city} - API failure (HTTP {http_status})")
            results.append({
                'city': city,
                'status': 'failed',
                'reason': f'API error (HTTP {http_status})'
            })
            print("")
            continue
        
        # Validate data and calculate quality metrics
        print(f"Validating data quality...")
        quality_metrics = validate_data(data, scheduled_time)
        
        # Check for schema drift
        previous_schema = get_previous_schema_version(city)
        schema_changed = False
        
        if previous_schema and previous_schema != quality_metrics['schema_version']:
            print(f"   SCHEMA DRIFT DETECTED!")
            print(f"      Previous: {previous_schema}")
            print(f"      Current:  {quality_metrics['schema_version']}")
            schema_changed = True
            quality_metrics['schema_drift_detected'] = True
        else:
            quality_metrics['schema_drift_detected'] = False
        
        # Display quality scores
        scores = quality_metrics['quality_scores']
        print(f"\nQuality Scores:")
        print(f"   Overall:      {scores['overall_quality_score']}/100")
        print(f"   Completeness: {scores['completeness_score']}/100")
        print(f"   Consistency:  {scores['consistency_score']}/100")
        print(f"   Timeliness:   {scores['timeliness_score']}/100")
        print(f"   Availability: {scores['availability_score']}/100")
        
        # Display quality issues if any
        if quality_metrics['has_issues']:
            print(f"\nQuality Issues Detected:")
            if quality_metrics['field_validation']['missing_fields']:
                print(f"   Missing fields: {quality_metrics['field_validation']['missing_fields']}")
            if quality_metrics['type_validation']['error_count'] > 0:
                print(f"   Type errors: {quality_metrics['type_validation']['error_count']}")
            if quality_metrics['range_validation']['error_count'] > 0:
                print(f"   Range errors: {quality_metrics['range_validation']['error_count']}")
        
        # Write to S3
        print(f"\nWriting to S3...")
        if write_to_s3(city, data, quality_metrics):
            # Send CloudWatch metrics
            print(f"Sending CloudWatch metrics...")
            send_cloudwatch_metrics(
                city,
                scores,
                latency_ms,
                quality_metrics['field_validation']['missing_percent'],
                schema_changed
            )
            
            results.append({
                'city': city,
                'status': 'success',
                'quality_score': scores['overall_quality_score'],
                'has_issues': quality_metrics['has_issues'],
                'schema_changed': schema_changed
            })
        else:
            results.append({
                'city': city,
                'status': 'failed',
                'reason': 'S3 write error'
            })
        
        print("")
    
    # Summary
    successful = len([r for r in results if r['status'] == 'success'])
    avg_quality = sum([r.get('quality_score', 0) for r in results if r['status'] == 'success']) / max(successful, 1)
    issues_count = sum([1 for r in results if r.get('has_issues', False)])
    schema_changes = sum([1 for r in results if r.get('schema_changed', False)])
    
    print("=" * 80)
    print(f"INGESTION SUMMARY")
    print(f"   Cities processed: {successful}/{len(CITIES)}")
    print(f"   Average quality:  {avg_quality:.1f}/100")
    print(f"   Issues detected:  {issues_count}")
    print(f"   Schema changes:   {schema_changes}")
    print("=" * 80)
    
    return {
        'statusCode': 200 if successful > 0 else 500,
        'body': json.dumps({
            'results': results,
            'summary': {
                'total': len(CITIES),
                'successful': successful,
                'average_quality_score': round(avg_quality, 2),
                'issues_detected': issues_count,
                'schema_changes': schema_changes
            }
        })
    }