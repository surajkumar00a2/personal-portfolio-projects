-- ============================================================
-- GOLD LAYER - COMPLETELY FIXED VERSION
-- All simple types, no STRUCT needed for Parquet
-- ============================================================

-- ============================================================
-- TABLE 1: Weather Daily Summary
-- ============================================================

DROP TABLE IF EXISTS weather_data_lake.gold_weather_daily_summary;

CREATE EXTERNAL TABLE weather_data_lake.gold_weather_daily_summary (
    city_name STRING,
    `date` DATE,
    avg_temperature_celsius DOUBLE,
    min_temperature_celsius DOUBLE,
    max_temperature_celsius DOUBLE,
    avg_feels_like_celsius DOUBLE,
    avg_humidity_percent DOUBLE,
    min_humidity_percent BIGINT,
    max_humidity_percent BIGINT,
    avg_pressure_hpa DOUBLE,
    avg_wind_speed_mps DOUBLE,
    max_wind_speed_mps DOUBLE,
    avg_wind_gust_mps DOUBLE,
    avg_cloudiness_percent DOUBLE,
    avg_visibility_meters DOUBLE,
    observations_count BIGINT,
    dominant_weather_condition STRING,
    first_observation_time TIMESTAMP,
    last_observation_time TIMESTAMP
)
PARTITIONED BY (
    year INT,
    month INT
)
STORED AS PARQUET
LOCATION 's3://weather-data-platform-13846/data/gold/weather_daily_summary/'
TBLPROPERTIES (
    'parquet.compression' = 'SNAPPY',
    'projection.enabled' = 'true',
    'projection.year.type' = 'integer',
    'projection.year.range' = '2020,2030',
    'projection.month.type' = 'integer',
    'projection.month.range' = '1,12',
    'projection.month.digits' = '1',
    'storage.location.template' = 's3://weather-data-platform-13846/data/gold/weather_daily_summary/year=${year}/month=${month}'
);


-- ============================================================
-- TABLE 2: Quality Scorecard Daily
-- ============================================================

DROP TABLE IF EXISTS weather_data_lake.gold_quality_scorecard_daily;

CREATE EXTERNAL TABLE weather_data_lake.gold_quality_scorecard_daily (
    `date` DATE,
    total_ingestions BIGINT,
    successful_ingestions BIGINT,
    failed_ingestions BIGINT,
    records_with_missing_fields BIGINT,
    schema_changes_detected BIGINT,
    volume_anomalies_detected BIGINT,
    avg_data_quality_score DOUBLE,
    min_data_quality_score DOUBLE,
    max_data_quality_score DOUBLE,
    completeness_score DOUBLE,
    consistency_score DOUBLE,
    timeliness_score DOUBLE,
    availability_score DOUBLE,
    overall_quality_score DOUBLE
)
PARTITIONED BY (
    year INT,
    month INT
)
STORED AS PARQUET
LOCATION 's3://weather-data-platform-13846/data/gold/quality_scorecard_daily/'
TBLPROPERTIES (
    'parquet.compression' = 'SNAPPY',
    'projection.enabled' = 'true',
    'projection.year.type' = 'integer',
    'projection.year.range' = '2020,2030',
    'projection.month.type' = 'integer',
    'projection.month.range' = '1,12',
    'projection.month.digits' = '1',
    'storage.location.template' = 's3://weather-data-platform-13846/data/gold/quality_scorecard_daily/year=${year}/month=${month}'
);


-- ============================================================
-- TABLE 3: Reliability Trends Weekly
-- ============================================================

DROP TABLE IF EXISTS weather_data_lake.gold_reliability_trends_weekly;

CREATE EXTERNAL TABLE weather_data_lake.gold_reliability_trends_weekly (
    week_start_date DATE,
    avg_quality_score DOUBLE,
    min_quality_score DOUBLE,
    max_quality_score DOUBLE,
    schema_changes BIGINT,
    volume_anomalies BIGINT,
    total_observations BIGINT,
    unique_cities BIGINT,
    api_availability_percent DOUBLE,
    schema_stable BOOLEAN,
    volume_stable BOOLEAN,
    total_alerts_generated BIGINT
)
PARTITIONED BY (
    year INT,
    week INT
)
STORED AS PARQUET
LOCATION 's3://weather-data-platform-13846/data/gold/reliability_trends_weekly/'
TBLPROPERTIES (
    'parquet.compression' = 'SNAPPY',
    'projection.enabled' = 'true',
    'projection.year.type' = 'integer',
    'projection.year.range' = '2020,2030',
    'projection.week.type' = 'integer',
    'projection.week.range' = '1,53',
    'projection.week.digits' = '1',
    'storage.location.template' = 's3://weather-data-platform-13846/data/gold/reliability_trends_weekly/year=${year}/week=${week}'
);


-- ============================================================
-- TEST QUERIES
-- ============================================================

-- Test weather summary
SELECT 
    city_name,
    date,
    avg_temperature_celsius,
    observations_count,
    year,
    month
FROM weather_data_lake.gold_weather_daily_summary
WHERE year = 2026 AND month = 1
ORDER BY date DESC, city_name
LIMIT 10;

-- Test quality scorecard
SELECT 
    date,
    overall_quality_score,
    total_ingestions,
    schema_changes_detected,
    year,
    month
FROM weather_data_lake.gold_quality_scorecard_daily
WHERE year = 2026 AND month = 1
ORDER BY date DESC
LIMIT 10;

-- Test weekly trends
SELECT 
    week_start_date,
    avg_quality_score,
    total_observations,
    schema_stable,
    volume_stable,
    year,
    week
FROM weather_data_lake.gold_reliability_trends_weekly
WHERE year = 2026
ORDER BY week_start_date DESC
LIMIT 10;