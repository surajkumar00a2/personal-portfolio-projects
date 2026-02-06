-- ============================================================
-- QUALITY ANALYSIS QUERIES
-- Analyze data quality trends and issues
-- ============================================================

-- Query 1: Overall Quality Score Trend (Last 30 Days)
-- Shows how data quality has changed over time
SELECT 
    date,
    overall_quality_score,
    completeness_score,
    consistency_score,
    total_ingestions,
    CASE 
        WHEN overall_quality_score >= 95 THEN 'EXCELLENT'
        WHEN overall_quality_score >= 80 THEN 'GOOD'
        WHEN overall_quality_score >= 60 THEN 'WARNING'
        ELSE 'CRITICAL'
    END as quality_status
FROM weather_data_lake.gold_quality_scorecard_daily
WHERE year = 2026 AND month = 2
ORDER BY date DESC;


-- Query 2: Days with Quality Issues
-- Find specific days where quality dropped below threshold
SELECT 
    date,
    overall_quality_score,
    records_with_missing_fields,
    schema_changes_detected,
    volume_anomalies_detected,
    total_ingestions
FROM weather_data_lake.gold_quality_scorecard_daily
WHERE overall_quality_score < 80
  AND year = 2026 
  AND month = 2
ORDER BY overall_quality_score ASC;


-- Query 3: Quality Score by Dimension
-- Compare different quality dimensions
SELECT 
    date,
    ROUND(completeness_score, 2) as avg_completeness,
    ROUND(consistency_score, 2) as avg_consistency,
    ROUND(timeliness_score, 2) as avg_timeliness,
    ROUND(availability_score, 2) as avg_availability,
    ROUND(overall_quality_score, 2) as avg_overall
FROM weather_data_lake.gold_quality_scorecard_daily
WHERE year = 2026 AND month = 2
ORDER BY date DESC;


-- Query 4: Missing Fields Analysis
-- Identify which fields are most commonly missing
SELECT 
    city,
    CAST(date AS DATE) as event_date,
    missing_fields,
    missing_percent,
    overall_quality_score as quality_score
FROM weather_data_lake.metrics_quality_events
WHERE missing_count > 0
  AND date >= '2026-02-01'
ORDER BY missing_percent DESC
LIMIT 100;


-- Query 5: Quality Score Distribution
-- Understand overall quality distribution
SELECT 
    CASE 
        WHEN overall_quality_score = 100 THEN '100 (Perfect)'
        WHEN overall_quality_score >= 95 THEN '95-99 (Excellent)'
        WHEN overall_quality_score >= 80 THEN '80-94 (Good)'
        WHEN overall_quality_score >= 60 THEN '60-79 (Warning)'
        ELSE '< 60 (Critical)'
    END as score_range,
    COUNT(*) as days_count,
    ROUND(AVG(total_ingestions), 0) as avg_daily_records
FROM weather_data_lake.gold_quality_scorecard_daily
WHERE year = 2026 AND month = 2
GROUP BY 
    CASE 
        WHEN overall_quality_score = 100 THEN '100 (Perfect)'
        WHEN overall_quality_score >= 95 THEN '95-99 (Excellent)'
        WHEN overall_quality_score >= 80 THEN '80-94 (Good)'
        WHEN overall_quality_score >= 60 THEN '60-79 (Warning)'
        ELSE '< 60 (Critical)'
    END
ORDER BY 
    CASE score_range
        WHEN '100 (Perfect)' THEN 1
        WHEN '95-99 (Excellent)' THEN 2
        WHEN '80-94 (Good)' THEN 3
        WHEN '60-79 (Warning)' THEN 4
        ELSE 5
    END;