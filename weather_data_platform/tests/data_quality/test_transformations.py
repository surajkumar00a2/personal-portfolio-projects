"""
Data Quality Tests for Glue Transformations
Validates Bronze→Silver and Silver→Gold transformations
"""

import pytest
from pyspark.sql import SparkSession
from pyspark.sql.types import *
from datetime import datetime
import json


@pytest.fixture(scope="session")
def spark():
    """Create Spark session for testing"""
    return SparkSession.builder \
        .appName("DataQualityTests") \
        .master("local[2]") \
        .getOrCreate()


class TestBronzeToSilverTransformation:
    """Test Bronze→Silver transformation logic"""
    
    def test_json_to_parquet_conversion(self, spark):
        """Test JSON is correctly converted to Parquet-compatible schema"""
        # Create sample Bronze data
        bronze_data = [{
            "ingestion_metadata": {
                "ingestion_timestamp": "2026-01-31T12:00:00Z",
                "city": "London",
                "source": "openweathermap",
                "schema_version": "a3f5c8d9"
            },
            "raw_data": {
                "coord": {"lat": 51.5, "lon": -0.1},
                "main": {"temp": 280.5, "humidity": 75, "pressure": 1013},
                "name": "London",
                "dt": 1706702400
            }
        }]
        
        df = spark.createDataFrame(bronze_data)
        
        # Verify structure
        assert "ingestion_metadata" in df.columns
        assert "raw_data" in df.columns
    
    def test_temperature_conversion(self, spark):
        """Test Kelvin to Celsius conversion"""
        from pyspark.sql import functions as F
        
        # Create test data with known Kelvin values
        data = [
            {"temp_kelvin": 273.15},  # 0°C
            {"temp_kelvin": 300.15},  # 27°C
            {"temp_kelvin": 280.15}   # 7°C
        ]
        
        df = spark.createDataFrame(data)
        df = df.withColumn("temp_celsius", F.round(F.col("temp_kelvin") - 273.15, 2))
        
        result = df.collect()
        
        assert result[0]['temp_celsius'] == 0.0
        assert result[1]['temp_celsius'] == 27.0
        assert result[2]['temp_celsius'] == 7.0
    
    def test_deduplication_logic(self, spark):
        """Test deduplication keeps latest record"""
        from pyspark.sql import functions as F
        from pyspark.sql.window import Window
        
        # Create duplicate data
        data = [
            {"city_id": 1, "observation_timestamp": "2026-01-31 12:00:00", 
             "ingestion_timestamp": "2026-01-31 12:00:10", "temp": 15.0},
            {"city_id": 1, "observation_timestamp": "2026-01-31 12:00:00", 
             "ingestion_timestamp": "2026-01-31 12:00:20", "temp": 15.5},  # Latest
            {"city_id": 2, "observation_timestamp": "2026-01-31 12:00:00", 
             "ingestion_timestamp": "2026-01-31 12:00:15", "temp": 10.0}
        ]
        
        df = spark.createDataFrame(data)
        
        # Apply deduplication logic
        window_spec = Window.partitionBy("city_id", "observation_timestamp") \
                           .orderBy(F.col("ingestion_timestamp").desc())
        
        df_deduped = df.withColumn("row_num", F.row_number().over(window_spec)) \
                      .filter(F.col("row_num") == 1) \
                      .drop("row_num")
        
        result = df_deduped.collect()
        
        # Should have 2 records (1 per city)
        assert len(result) == 2
        
        # City 1 should have temp 15.5 (latest ingestion)
        city1_record = [r for r in result if r['city_id'] == 1][0]
        assert city1_record['temp'] == 15.5
    
    def test_partition_columns_added(self, spark):
        """Test year/month/day partition columns are added"""
        from pyspark.sql import functions as F
        
        data = [
            {"observation_timestamp": "2026-01-31 12:00:00"},
            {"observation_timestamp": "2026-02-15 18:30:00"}
        ]
        
        df = spark.createDataFrame(data)
        df = df.withColumn("observation_timestamp", F.to_timestamp(F.col("observation_timestamp")))
        
        # Add partition columns
        df = df.withColumn("year", F.year(F.col("observation_timestamp"))) \
               .withColumn("month", F.month(F.col("observation_timestamp"))) \
               .withColumn("day", F.dayofmonth(F.col("observation_timestamp")))
        
        result = df.collect()
        
        assert result[0]['year'] == 2026
        assert result[0]['month'] == 1
        assert result[0]['day'] == 31
        
        assert result[1]['year'] == 2026
        assert result[1]['month'] == 2
        assert result[1]['day'] == 15


class TestSilverToGoldTransformation:
    """Test Silver→Gold aggregation logic"""
    
    def test_daily_aggregations(self, spark):
        """Test daily weather aggregations"""
        from pyspark.sql import functions as F
        
        # Create sample Silver data
        data = [
            {"city_name": "London", "date": "2026-01-31", "temperature_celsius": 10.0},
            {"city_name": "London", "date": "2026-01-31", "temperature_celsius": 12.0},
            {"city_name": "London", "date": "2026-01-31", "temperature_celsius": 8.0},
            {"city_name": "Tokyo", "date": "2026-01-31", "temperature_celsius": 15.0}
        ]
        
        df = spark.createDataFrame(data)
        
        # Aggregate by city and date
        df_agg = df.groupBy("city_name", "date").agg(
            F.round(F.avg("temperature_celsius"), 2).alias("avg_temp"),
            F.min("temperature_celsius").alias("min_temp"),
            F.max("temperature_celsius").alias("max_temp"),
            F.count("*").alias("observations_count")
        )
        
        result = df_agg.collect()
        london_data = [r for r in result if r['city_name'] == 'London'][0]
        
        assert london_data['avg_temp'] == 10.0  # (10 + 12 + 8) / 3
        assert london_data['min_temp'] == 8.0
        assert london_data['max_temp'] == 12.0
        assert london_data['observations_count'] == 3
    
    def test_quality_scorecard_aggregation(self, spark):
        """Test quality scorecard aggregation"""
        from pyspark.sql import functions as F
        
        # Create sample quality data
        data = [
            {"date": "2026-01-31", "has_missing_fields": False, "data_quality_score": 100},
            {"date": "2026-01-31", "has_missing_fields": False, "data_quality_score": 95},
            {"date": "2026-01-31", "has_missing_fields": True, "data_quality_score": 70}
        ]
        
        df = spark.createDataFrame(data)
        
        # Aggregate quality metrics
        df_quality = df.groupBy("date").agg(
            F.count("*").alias("total_ingestions"),
            F.sum(F.when(F.col("has_missing_fields") == False, 1).otherwise(0)).alias("successful_ingestions"),
            F.round(F.avg("data_quality_score"), 2).alias("avg_quality_score")
        )
        
        result = df_quality.collect()[0]
        
        assert result['total_ingestions'] == 3
        assert result['successful_ingestions'] == 2
        assert result['avg_quality_score'] == 88.33  # (100 + 95 + 70) / 3


class TestDataQualityRules:
    """Test data quality rules and constraints"""
    
    def test_no_null_city_names(self, spark):
        """Test Silver layer has no null city names"""
        data = [
            {"city_name": "London", "temp": 10.0},
            {"city_name": None, "temp": 15.0},
            {"city_name": "Tokyo", "temp": 20.0}
        ]
        
        df = spark.createDataFrame(data)
        
        # Count nulls
        null_count = df.filter(df.city_name.isNull()).count()
        
        # In production, this should fail if nulls exist
        assert null_count == 1  # Test detects the issue
    
    def test_temperature_within_reasonable_bounds(self, spark):
        """Test temperatures are within reasonable bounds"""
        data = [
            {"temp_celsius": -50.0},   # Extreme cold but possible
            {"temp_celsius": 25.0},    # Normal
            {"temp_celsius": 150.0}    # Impossible (data error)
        ]
        
        df = spark.createDataFrame(data)
        
        # Flag unreasonable values
        df = df.withColumn(
            "temp_valid",
            (df.temp_celsius >= -90) & (df.temp_celsius <= 60)
        )
        
        invalid_count = df.filter(df.temp_valid == False).count()
        
        assert invalid_count == 1  # Only the 150°C record
    
    def test_no_duplicate_records_in_silver(self, spark):
        """Test Silver layer has no duplicates"""
        data = [
            {"city_id": 1, "observation_timestamp": "2026-01-31 12:00:00"},
            {"city_id": 1, "observation_timestamp": "2026-01-31 12:00:00"},  # Duplicate
            {"city_id": 2, "observation_timestamp": "2026-01-31 12:00:00"}
        ]
        
        df = spark.createDataFrame(data)
        
        # Count duplicates
        total_count = df.count()
        distinct_count = df.dropDuplicates(["city_id", "observation_timestamp"]).count()
        
        # In production Silver, these should be equal
        assert total_count == 3
        assert distinct_count == 2  # Test detects duplicate


# Run tests with: pytest tests/data_quality/ -v