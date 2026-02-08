-- ============================================================
-- QUICKSIGHT-OPTIMIZED VIEWS
-- Pre-aggregated views for fast dashboard loading
-- ============================================================

-- View 1: Quality Trends (Last 30 Days)
CREATE OR REPLACE VIEW weather_data_lake.qs_quality_trends_30d AS
SELECT 
    date,
    overall_quality_score,
    completeness_score,
    consistency_score,
    timeliness_score,
    total_ingestions,
    records_with_missing_fields,
    schema_changes_detected,
    CASE 
        WHEN overall_quality_score >= 95 THEN 'Excellent'
        WHEN overall_quality_score >= 80 THEN 'Good'
        WHEN overall_quality_score >= 60 THEN 'Warning'
        ELSE 'Critical'
    END as quality_status
FROM weather_data_lake.gold_quality_scorecard_daily
WHERE date >= CURRENT_DATE - INTERVAL '30' DAY
ORDER BY date DESC;


-- View 2: Weather Summary (Last 7 Days)
CREATE OR REPLACE VIEW weather_data_lake.qs_weather_summary_7d AS
SELECT 
    city_name,
    date,
    avg_temperature_celsius,
    min_temperature_celsius,
    max_temperature_celsius,
    avg_humidity_percent,
    avg_wind_speed_mps,
    dominant_weather_condition,
    observations_count
FROM weather_data_lake.gold_weather_daily_summary
WHERE date >= CURRENT_DATE - INTERVAL '7' DAY
ORDER BY date DESC, city_name;


-- View 3: City Comparison (Current Month)
CREATE OR REPLACE VIEW weather_data_lake.qs_city_comparison_monthly AS
SELECT 
    city_name,
    COUNT(*) as days_of_data,
    ROUND(AVG(avg_temperature_celsius), 2) as avg_monthly_temp,
    ROUND(MIN(min_temperature_celsius), 2) as coldest_temp,
    ROUND(MAX(max_temperature_celsius), 2) as warmest_temp,
    ROUND(AVG(avg_humidity_percent), 2) as avg_monthly_humidity,
    SUM(observations_count) as total_observations
FROM weather_data_lake.gold_weather_daily_summary
WHERE year = YEAR(CURRENT_DATE) 
  AND month = MONTH(CURRENT_DATE)
GROUP BY city_name;


-- View 4: Schema Stability (Last 90 Days)
CREATE OR REPLACE VIEW weather_data_lake.qs_schema_stability_90d AS
SELECT 
    week_start_date,
    avg_quality_score,
    schema_changes,
    volume_anomalies,
    total_observations,
    schema_stable,
    volume_stable,
    CASE 
        WHEN schema_stable AND volume_stable THEN 'Stable'
        WHEN schema_changes > 0 THEN 'Schema Changed'
        WHEN volume_anomalies > 0 THEN 'Volume Anomaly'
        ELSE 'Unknown'
    END as stability_status
FROM weather_data_lake.gold_reliability_trends_weekly
WHERE week_start_date >= CURRENT_DATE - INTERVAL '90' DAY
ORDER BY week_start_date DESC;


-- View 5: Real-Time Quality Scorecard
CREATE OR REPLACE VIEW weather_data_lake.qs_realtime_scorecard AS
WITH latest_metrics AS (
    SELECT 
        city,
        ingestion_timestamp,
        overall_quality_score,
        completeness_score,
        consistency_score,
        has_issues,
        schema_drift_detected,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY ingestion_timestamp DESC) as rn
    FROM weather_data_lake.metrics_quality_events
    WHERE date >= CAST(CURRENT_DATE - INTERVAL '1' DAY AS VARCHAR)
)
SELECT 
    city,
    ingestion_timestamp as last_update,
    overall_quality_score,
    completeness_score,
    consistency_score,
    has_issues,
    schema_drift_detected,
    CASE 
        WHEN overall_quality_score >= 95 THEN '🟢 Excellent'
        WHEN overall_quality_score >= 80 THEN '🟡 Good'
        WHEN overall_quality_score >= 60 THEN '🟠 Warning'
        ELSE '🔴 Critical'
    END as status
FROM latest_metrics
WHERE rn = 1;