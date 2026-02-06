-- ============================================================
-- WEATHER ANALYTICS QUERIES
-- Business intelligence queries on weather data
-- ============================================================

-- Query 1: Temperature Trends by City
-- Daily temperature comparison across cities
SELECT 
    date,
    city_name,
    avg_temperature_celsius,
    min_temperature_celsius,
    max_temperature_celsius,
    (max_temperature_celsius - min_temperature_celsius) as daily_temperature_range
FROM weather_data_lake.gold_weather_daily_summary
WHERE year = 2026 AND month = 2
ORDER BY date DESC, city_name;


-- Query 2: Coldest and Warmest Days
-- Find temperature extremes
WITH coldest AS (
    SELECT 
        'Coldest' as category,
        date,
        city_name,
        min_temperature_celsius as temperature
    FROM weather_data_lake.gold_weather_daily_summary
    WHERE year = 2026 AND month = 2
    ORDER BY min_temperature_celsius ASC
    LIMIT 5
),
warmest AS (
    SELECT 
        'Warmest' as category,
        date,
        city_name,
        max_temperature_celsius as temperature
    FROM weather_data_lake.gold_weather_daily_summary
    WHERE year = 2026 AND month = 2
    ORDER BY max_temperature_celsius DESC
    LIMIT 5
)
SELECT * FROM coldest
UNION ALL
SELECT * FROM warmest;


-- Query 3: Weather Condition Frequency
-- Most common weather conditions
SELECT 
    city_name,
    dominant_weather_condition,
    COUNT(*) as days_count,
    ROUND(AVG(avg_temperature_celsius), 2) as avg_temp_celsius
FROM weather_data_lake.gold_weather_daily_summary
WHERE year = 2026 AND month = 2
GROUP BY city_name, dominant_weather_condition
ORDER BY city_name, days_count DESC;


-- Query 4: Humidity Analysis
-- Find patterns in humidity levels
SELECT 
    date,
    city_name,
    avg_humidity_percent,
    min_humidity_percent,
    max_humidity_percent,
    CASE 
        WHEN avg_humidity_percent > 80 THEN 'Very Humid'
        WHEN avg_humidity_percent > 60 THEN 'Humid'
        WHEN avg_humidity_percent > 40 THEN 'Comfortable'
        ELSE 'Dry'
    END as humidity_category
FROM weather_data_lake.gold_weather_daily_summary
WHERE year = 2026 AND month = 2
ORDER BY date DESC, city_name;


-- Query 5: Wind Speed Trends
-- Identify windy days
SELECT 
    date,
    city_name,
    avg_wind_speed_mps,
    max_wind_speed_mps,
    avg_wind_gust_mps,
    CASE 
        WHEN max_wind_speed_mps > 15 THEN 'Very Windy'
        WHEN max_wind_speed_mps > 10 THEN 'Windy'
        WHEN max_wind_speed_mps > 5 THEN 'Moderate'
        ELSE 'Calm'
    END as wind_category
FROM weather_data_lake.gold_weather_daily_summary
WHERE year = 2026 AND month = 2
ORDER BY max_wind_speed_mps DESC
LIMIT 20;


-- Query 6: Monthly City Comparison
-- Compare cities across the month
SELECT 
    city_name,
    COUNT(*) as days_with_data,
    ROUND(AVG(avg_temperature_celsius), 2) as avg_monthly_temp,
    ROUND(AVG(avg_humidity_percent), 2) as avg_monthly_humidity,
    ROUND(AVG(avg_wind_speed_mps), 2) as avg_monthly_wind_speed,
    SUM(observations_count) as total_observations
FROM weather_data_lake.gold_weather_daily_summary
WHERE year = 2026 AND month = 2
GROUP BY city_name
ORDER BY city_name;