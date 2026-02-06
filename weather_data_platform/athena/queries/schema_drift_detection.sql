-- ============================================================
-- SCHEMA DRIFT DETECTION QUERIES
-- Track schema changes over time
-- ============================================================

-- Query 1: Schema Changes Over Time
-- Identify when schema changed
SELECT 
    date,
    hour,
    city,
    schema_version,
    LAG(schema_version) OVER (PARTITION BY city ORDER BY date, hour) as previous_schema,
    schema_drift_detected,
    overall_quality_score as quality_score
FROM weather_data_lake.metrics_quality_events
WHERE date >= '2026-02-01'
ORDER BY date DESC, hour DESC, city;


-- Query 2: Schema Version History
-- Show all distinct schema versions per city
SELECT 
    city,
    schema_version,
    MIN(CAST(date AS DATE)) as first_seen,
    MAX(CAST(date AS DATE)) as last_seen,
    COUNT(*) as occurrences
FROM weather_data_lake.metrics_quality_events
WHERE date >= '2026-02-01'
GROUP BY city, schema_version
ORDER BY city, first_seen;


-- Query 3: Days with Schema Changes
-- Find specific instances of schema drift
SELECT 
    date,
    COUNT(DISTINCT city) as cities_affected,
    ARRAY_AGG(DISTINCT schema_version) as schema_versions_detected,
    SUM(CASE WHEN schema_drift_detected THEN 1 ELSE 0 END) as drift_count
FROM weather_data_lake.metrics_quality_events
WHERE schema_drift_detected = true
  AND date >= '2026-02-01'
GROUP BY date
ORDER BY date DESC;


-- Query 4: Schema Stability Score
-- Calculate how stable schema has been
SELECT 
    city,
    COUNT(DISTINCT schema_version) as total_schema_versions,
    COUNT(*) as total_ingestions,
    ROUND(100.0 * (1.0 - CAST(COUNT(DISTINCT schema_version) - 1 AS DOUBLE) / COUNT(*)), 2) as stability_score
FROM weather_data_lake.metrics_quality_events
WHERE date >= '2026-02-01'
  AND date < '2026-03-01'
GROUP BY city
ORDER BY stability_score DESC;