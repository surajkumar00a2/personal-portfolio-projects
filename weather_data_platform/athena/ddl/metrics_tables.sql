-- ============================================================
-- METRICS LAYER TABLE DEFINITION
-- Quality metrics from Lambda ingestion (PARQUET FORMAT)
-- ============================================================

-- Drop existing table if needed
DROP TABLE IF EXISTS weather_data_lake.metrics_quality_events;

CREATE EXTERNAL TABLE IF NOT EXISTS weather_data_lake.metrics_quality_events (
    city STRING,
    ingestion_timestamp TIMESTAMP,
    validation_timestamp TIMESTAMP,
    schema_version STRING,
    
    total_fields INT,
    populated_fields INT,
    missing_fields STRING,       
    missing_count INT,
    missing_percent DOUBLE,
    
    type_errors STRING,           
    type_error_count INT,
    
    range_errors STRING,    
    range_error_count INT,
    
    completeness_score DOUBLE,
    consistency_score DOUBLE,
    timeliness_score DOUBLE,
    availability_score DOUBLE,
    overall_quality_score DOUBLE,
    
    has_issues BOOLEAN,
    schema_drift_detected BOOLEAN
)
PARTITIONED BY (
    `date` STRING,
    `hour` STRING
)
STORED AS PARQUET
LOCATION 's3://weather-data-platform-13846/metrics/quality/'
TBLPROPERTIES (
    'projection.enabled' = 'true',
    'projection.date.type' = 'date',
    'projection.date.range' = '2026-01-01,NOW',
    'projection.date.format' = 'yyyy-MM-dd',
    'projection.hour.type' = 'enum',
    'projection.hour.values' = '00,06,12,18',
    'storage.location.template' = 's3://weather-data-platform-13846/metrics/quality/date=${date}/hour=${hour}',
    'parquet.compression' = 'SNAPPY'
);

-- Verify table created
DESCRIBE weather_data_lake.metrics_quality_events;

-- Sample query
SELECT 
    city,
    ingestion_timestamp,
    schema_version,
    overall_quality_score,
    completeness_score,
    consistency_score,
    has_issues,
    schema_drift_detected,
    date,
    hour
FROM weather_data_lake.metrics_quality_events
WHERE date >= '2026-01-31'
ORDER BY ingestion_timestamp DESC
LIMIT 10;

-- Query to parse missing_fields (stored as string)
SELECT 
    city,
    date,
    missing_fields,
    missing_count,
    overall_quality_score
FROM weather_data_lake.metrics_quality_events
WHERE missing_count > 0
ORDER BY date DESC, missing_count DESC
LIMIT 20;