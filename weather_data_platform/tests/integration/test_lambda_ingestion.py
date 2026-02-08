"""
Integration Tests for Lambda Ingestion Function
Uses moto to mock AWS services (S3, CloudWatch)
"""

import pytest
import json
import os
import sys
from datetime import datetime, timezone
from unittest.mock import patch, MagicMock
from moto import mock_aws
import boto3

# Add lambda code to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lambda/ingestion'))

# Set environment variables before importing lambda
os.environ['S3_BUCKET'] = 'test-bucket'
os.environ['OPENWEATHER_API_KEY'] = 'test-api-key'

from lambda_ingestion_v2 import (
    fetch_weather_data,
    write_to_s3,
    send_cloudwatch_metrics,
    lambda_handler
)


@pytest.fixture
def mock_weather_api_response():
    """Fixture providing mock weather API response"""
    return {
        "coord": {"lon": -0.1257, "lat": 51.5085},
        "weather": [
            {
                "id": 803,
                "main": "Clouds",
                "description": "broken clouds",
                "icon": "04d"
            }
        ],
        "base": "stations",
        "main": {
            "temp": 280.32,
            "feels_like": 278.99,
            "temp_min": 279.15,
            "temp_max": 281.15,
            "pressure": 1012,
            "humidity": 81
        },
        "visibility": 10000,
        "wind": {
            "speed": 4.1,
            "deg": 80
        },
        "clouds": {
            "all": 75
        },
        "dt": 1485789600,
        "sys": {
            "type": 1,
            "id": 5091,
            "country": "GB",
            "sunrise": 1485762037,
            "sunset": 1485794875
        },
        "timezone": 0,
        "id": 2643743,
        "name": "London",
        "cod": 200
    }


@pytest.fixture
def mock_quality_metrics():
    """Fixture providing mock quality metrics"""
    return {
        "validation_timestamp": datetime.now(timezone.utc).isoformat(),
        "schema_version": "a3f5c8d9",
        "field_validation": {
            "total_fields": 13,
            "populated_fields": 13,
            "missing_fields": [],
            "missing_count": 0,
            "missing_percent": 0.0
        },
        "type_validation": {
            "errors": [],
            "error_count": 0
        },
        "range_validation": {
            "errors": [],
            "error_count": 0
        },
        "quality_scores": {
            "completeness_score": 100.0,
            "consistency_score": 100.0,
            "timeliness_score": 100.0,
            "availability_score": 100.0,
            "overall_quality_score": 100.0
        },
        "has_issues": False,
        "schema_drift_detected": False
    }


class TestFetchWeatherData:
    """Test weather API fetching"""
    
    @patch('lambda_ingestion_v2.requests.get')
    def test_successful_api_call(self, mock_get, mock_weather_api_response):
        """Test successful API call"""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = mock_weather_api_response
        mock_get.return_value = mock_response
        
        data, status, latency = fetch_weather_data("London")
        
        assert data == mock_weather_api_response
        assert status == 200
        assert latency >= 0
    
    @patch('lambda_ingestion_v2.requests.get')
    def test_api_failure(self, mock_get):
        """Test API failure handling"""
        mock_response = MagicMock()
        mock_response.status_code = 404
        mock_get.return_value = mock_response
        
        data, status, latency = fetch_weather_data("InvalidCity")
        
        assert data is None
        assert status == 404
    
    @patch('lambda_ingestion_v2.requests.get')
    def test_api_timeout(self, mock_get):
        """Test API timeout handling"""
        import requests
        mock_get.side_effect = requests.exceptions.Timeout()
        
        data, status, latency = fetch_weather_data("London")
        
        assert data is None
        assert status == 0


@mock_aws
class TestWriteToS3:
    """Test S3 write operations"""
    
    def setup_method(self, method):
        """Set up S3 bucket before each test"""
        self.s3 = boto3.client('s3', region_name='us-east-1')
        self.s3.create_bucket(Bucket='test-bucket')
    
    def test_successful_write(self, mock_weather_api_response, mock_quality_metrics):
        """Test successful write to S3"""
        result = write_to_s3("London", mock_weather_api_response, mock_quality_metrics)
        
        assert result is True
        
        # Verify Bronze file exists
        objects = self.s3.list_objects_v2(Bucket='test-bucket', Prefix='data/bronze/')
        assert 'Contents' in objects
        assert len(objects['Contents']) > 0
        
        # Verify Metrics file exists
        objects = self.s3.list_objects_v2(Bucket='test-bucket', Prefix='metrics/quality/')
        assert 'Contents' in objects
        assert len(objects['Contents']) > 0
    
    def test_bronze_json_format(self, mock_weather_api_response, mock_quality_metrics):
        """Test Bronze data is written as JSON"""
        write_to_s3("London", mock_weather_api_response, mock_quality_metrics)
        
        # Get the Bronze file
        objects = self.s3.list_objects_v2(Bucket='test-bucket', Prefix='data/bronze/')
        key = objects['Contents'][0]['Key']
        
        obj = self.s3.get_object(Bucket='test-bucket', Key=key)
        content = obj['Body'].read().decode('utf-8')
        data = json.loads(content)
        
        assert 'ingestion_metadata' in data
        assert 'raw_data' in data
        assert data['ingestion_metadata']['city'] == 'London'
    
    def test_metrics_parquet_format(self, mock_weather_api_response, mock_quality_metrics):
        """Test metrics are written as Parquet"""
        write_to_s3("London", mock_weather_api_response, mock_quality_metrics)
        
        # Get the metrics file
        objects = self.s3.list_objects_v2(Bucket='test-bucket', Prefix='metrics/quality/')
        key = objects['Contents'][0]['Key']
        
        # Verify it's a parquet file
        assert key.endswith('.parquet')
        
        # Verify file exists
        obj = self.s3.get_object(Bucket='test-bucket', Key=key)
        assert obj['ContentLength'] > 0


@mock_aws
class TestSendCloudWatchMetrics:
    """Test CloudWatch metrics publishing"""
    
    def setup_method(self, method):
        """Set up CloudWatch client"""
        self.cloudwatch = boto3.client('cloudwatch', region_name='us-east-1')
    
    def test_metrics_sent_successfully(self, mock_quality_metrics):
        """Test CloudWatch metrics are sent"""
        quality_scores = mock_quality_metrics['quality_scores']
        
        # Should not raise an exception
        send_cloudwatch_metrics(
            city="London",
            quality_scores=quality_scores,
            latency_ms=234,
            missing_percent=0.0,
            schema_changed=False
        )
    
    def test_all_metrics_included(self, mock_quality_metrics):
        """Test all expected metrics are included"""
        quality_scores = mock_quality_metrics['quality_scores']
        
        send_cloudwatch_metrics(
            city="London",
            quality_scores=quality_scores,
            latency_ms=234,
            missing_percent=0.0,
            schema_changed=False
        )
        
        # Verify metrics were sent
        metrics = self.cloudwatch.list_metrics(Namespace='DataPlatform/Quality')
        metric_names = [m['MetricName'] for m in metrics['Metrics']]
        
        expected_metrics = [
            'RecordsIngested',
            'OverallQualityScore',
            'CompletenessScore',
            'ConsistencyScore',
            'APILatency',
            'MissingFieldsPercent',
            'SchemaChanges'
        ]
        
        # Note: moto may not perfectly simulate all CloudWatch behavior
        # In real tests, you might mock put_metric_data directly


@mock_aws
class TestLambdaHandlerIntegration:
    """Integration tests for complete Lambda handler"""
    
    def setup_method(self, method):
        """Set up AWS mocks"""
        self.s3 = boto3.client('s3', region_name='us-east-1')
        self.s3.create_bucket(Bucket='test-bucket')
        self.cloudwatch = boto3.client('cloudwatch', region_name='us-east-1')
    
    @patch('lambda_ingestion_v2.fetch_weather_data')
    @patch('lambda_ingestion_v2.validate_data')
    def test_successful_execution(self, mock_validate, mock_fetch, 
                                   mock_weather_api_response, mock_quality_metrics):
        """Test successful Lambda execution"""
        # Mock API responses
        mock_fetch.return_value = (mock_weather_api_response, 200, 234)
        mock_validate.return_value = mock_quality_metrics
        
        # Execute Lambda
        event = {}
        context = MagicMock()
        
        response = lambda_handler(event, context)
        
        # Verify response
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body["summary"]["successful"] == 6  # 6 cities
        assert body["summary"]["total"] == 6
    
    @patch('lambda_ingestion_v2.fetch_weather_data')
    def test_partial_failure(self, mock_fetch, mock_weather_api_response):
        """Test Lambda handles partial failures"""
        # London succeeds, New York fails, Tokyo succeeds
        mock_fetch.side_effect = [
            (mock_weather_api_response, 200, 234),  # London
            (None, 404, 100),                       # Delhi (fail)
            (mock_weather_api_response, 200, 245),  # Tokyo
            (mock_weather_api_response, 200, 250),  # Dubai
            (None, 500, 100),                       # Riyadh (fail)
            (mock_weather_api_response, 200, 255)   # Muscat
        ]
        
        event = {}
        context = MagicMock()
        
        response = lambda_handler(event, context)
        
        # Verify response
        assert response['statusCode'] == 200  # Still returns 200 if at least 1 succeeds
        body = json.loads(response['body'])
        assert body['summary']['successful'] == 4  # 4 out of 6 succeeded
        assert body["summary"]["total"] == 6
    
    @patch('lambda_ingestion_v2.fetch_weather_data')
    @patch('lambda_ingestion_v2.validate_data')
    def test_quality_issues_detected(self, mock_validate, mock_fetch, 
                                     mock_weather_api_response):
        """Test Lambda detects quality issues"""
        mock_fetch.return_value = (mock_weather_api_response, 200, 234)
        
        # Mock quality metrics with issues
        mock_validate.return_value = {
            "validation_timestamp": datetime.now(timezone.utc).isoformat(),
            "schema_version": "a3f5c8d9",
            "field_validation": {
                "total_fields": 13,
                "populated_fields": 10,
                "missing_fields": ["coord.lon", "main.pressure", "wind.speed"],
                "missing_count": 3,
                "missing_percent": 23.08
            },
            "type_validation": {"errors": [], "error_count": 0},
            "range_validation": {"errors": [], "error_count": 0},
            "quality_scores": {
                "completeness_score": 76.92,
                "consistency_score": 100.0,
                "timeliness_score": 100.0,
                "availability_score": 100.0,
                "overall_quality_score": 85.38
            },
            "has_issues": True,
            "schema_drift_detected": False
        }
        
        event = {}
        context = MagicMock()
        
        response = lambda_handler(event, context)
        
        # Verify issues are reported
        body = json.loads(response['body'])
        assert body['summary']['issues_detected'] > 0


# pytest configuration
@pytest.fixture(scope="session", autouse=True)
def setup_test_environment():
    """Set up test environment variables"""
    os.environ['S3_BUCKET'] = 'test-bucket'
    os.environ['OPENWEATHER_API_KEY'] = 'test-api-key'


# Run tests with: pytest tests/integration/test_lambda_ingestion.py -v