-- ============================================================
-- REUSABLE VIEWS
-- Commonly used query patterns as views
-- ============================================================

-- View 1: Recent Quality Issues
-- Quick view of recent data quality problems
CREATE OR REPLACE VIEW weather_data_lake.v_recent_quality_issues AS
SELECT 
    date,
    overall_quality_score,
    completeness_score,
    consistency_score,
    records_with_missing_fields,
    schema_changes_detected,
    volume_anomalies_detected,
    total_ingestions,
    CASE 
        WHEN overall_quality_score < 60 THEN 'CRITICAL'
        WHEN overall_quality_score < 80 THEN 'WARNING'
        WHEN overall_quality_score < 95 THEN 'GOOD'
        ELSE 'EXCELLENT'
    END as status,
    year,
    month
FROM weather_data_lake.gold_quality_scorecard_daily
WHERE overall_quality_score < 100
  AND year = 2026 
  AND month = 2;


-- View 2: Schema Drift History
-- Track schema changes
CREATE OR REPLACE VIEW weather_data_lake.v_schema_drift_history AS
SELECT 
    date,
    hour,
    city,
    schema_version,
    LAG(schema_version) OVER (PARTITION BY city ORDER BY date, hour) as previous_schema_version,
    schema_drift_detected,
    overall_quality_score as quality_score
FROM weather_data_lake.metrics_quality_events
WHERE schema_drift_detected = true
  AND date >= '2026-02-01';


-- View 3: Latest Weather by City
-- Most recent weather observation per city
CREATE OR REPLACE VIEW weather_data_lake.v_latest_weather AS
SELECT 
    city_name,
    temperature_celsius,
    feels_like_celsius,
    humidity_percent,
    pressure_hpa,
    wind_speed_mps,
    weather_description,
    observation_timestamp,
    year,
    month,
    day
FROM (
    SELECT 
        city_name,
        temperature_celsius,
        feels_like_celsius,
        humidity_percent,
        pressure_hpa,
        wind_speed_mps,
        weather_description,
        observation_timestamp,
        year,
        month,
        day,
        ROW_NUMBER() OVER (PARTITION BY city_name ORDER BY observation_timestamp DESC) as rn
    FROM weather_data_lake.silver_weather_data
    WHERE year = 2026 AND month = 2
)
WHERE rn = 1;


-- View 4: Quality Scorecard Summary
-- High-level quality overview
CREATE OR REPLACE VIEW weather_data_lake.v_quality_summary AS
SELECT 
    'Last 7 Days' as period,
    ROUND(AVG(overall_quality_score), 2) as avg_quality_score,
    MIN(overall_quality_score) as min_quality_score,
    MAX(overall_quality_score) as max_quality_score,
    SUM(total_ingestions) as total_records,
    SUM(schema_changes_detected) as total_schema_changes,
    SUM(volume_anomalies_detected) as total_volume_anomalies
FROM weather_data_lake.gold_quality_scorecard_daily
WHERE year = 2026 AND month = 2;


-- View 5: Temperature Extremes
-- Hottest and coldest readings
CREATE OR REPLACE VIEW weather_data_lake.v_temperature_extremes AS
SELECT 
    city_name,
    date,
    'Hottest' as extreme_type,
    max_temperature_celsius as temperature,
    dominant_weather_condition,
    year,
    month
FROM (
    SELECT 
        city_name,
        date,
        max_temperature_celsius,
        dominant_weather_condition,
        year,
        month,
        ROW_NUMBER() OVER (ORDER BY max_temperature_celsius DESC) as rn
    FROM weather_data_lake.gold_weather_daily_summary
    WHERE year = 2026 AND month = 2
)
WHERE rn <= 10

UNION ALL

SELECT 
    city_name,
    date,
    'Coldest' as extreme_type,
    min_temperature_celsius as temperature,
    dominant_weather_condition,
    year,
    month
FROM (
    SELECT 
        city_name,
        date,
        min_temperature_celsius,
        dominant_weather_condition,
        year,
        month,
        ROW_NUMBER() OVER (ORDER BY min_temperature_celsius ASC) as rn
    FROM weather_data_lake.gold_weather_daily_summary
    WHERE year = 2026 AND month = 2
)
WHERE rn <= 10;


-- Test views
SELECT * FROM weather_data_lake.v_recent_quality_issues LIMIT 5;
SELECT * FROM weather_data_lake.v_latest_weather;
SELECT * FROM weather_data_lake.v_quality_summary;