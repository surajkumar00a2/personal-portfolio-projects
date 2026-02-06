-- ============================================================
-- SILVER LAYER - COMPLETELY FIXED VERSION
-- Parquet format, simple column types (no complex STRUCT)
-- ============================================================

-- Drop existing table
DROP TABLE IF EXISTS weather_data_lake.silver_weather_data;

-- Recreate - Parquet uses simple types
-- ============================================================
-- SILVER LAYER - FIXED & ALIGNED WITH GLUE OUTPUT
-- ============================================================

DROP TABLE IF EXISTS weather_data_lake.silver_weather_data;

CREATE EXTERNAL TABLE weather_data_lake.silver_weather_data (
    ingestion_timestamp TIMESTAMP,
    ingestion_city STRING,
    ingestion_source STRING,
    schema_version STRING,
    city_id BIGINT,
    city_name STRING,
    country_code STRING,
    longitude DOUBLE,
    latitude DOUBLE,
    temperature_celsius DOUBLE,
    feels_like_celsius DOUBLE,
    temp_min_celsius DOUBLE,
    temp_max_celsius DOUBLE,
    humidity_percent BIGINT,
    pressure_hpa BIGINT,
    sea_level_pressure_hpa BIGINT,
    ground_level_pressure_hpa BIGINT,
    wind_speed_mps DOUBLE,
    wind_direction_deg BIGINT,
    wind_gust_mps DOUBLE,
    cloudiness_percent BIGINT,
    visibility_meters BIGINT,
    observation_timestamp TIMESTAMP,
    sunrise_time TIMESTAMP,
    sunset_time TIMESTAMP,
    timezone_offset_seconds BIGINT,
    api_response_code BIGINT,
    weather_id BIGINT,
    weather_main STRING,
    weather_description STRING,
    weather_icon STRING,
    has_missing_fields BOOLEAN,
    schema_drift_detected BOOLEAN,
    is_volume_anomaly BOOLEAN,
    data_quality_score DOUBLE
)
PARTITIONED BY (
    year INT,
    month INT,
    day INT
)
STORED AS PARQUET
LOCATION 's3://weather-data-platform-13846/data/silver/'
TBLPROPERTIES (
    'parquet.compression' = 'SNAPPY'
);

MSCK REPAIR TABLE weather_data_lake.silver_weather_data;

SHOW PARTITIONS weather_data_lake.silver_weather_data;


-- Test query
-- #1
SELECT COUNT(*) as total_records 
FROM weather_data_lake.silver_weather_data;

-- #2
SELECT 
    city_name,
    observation_timestamp,
    temperature_celsius,
    humidity_percent,
    wind_speed_mps,
    data_quality_score,
    year,
    month,
    day
FROM weather_data_lake.silver_weather_data
WHERE year = 2026 AND month = 2
ORDER BY observation_timestamp DESC
LIMIT 10;