"""
Bronze to Silver Transformation
----------------------------------------
Reads raw JSON to Bronze layer, cleans, validates,a dn writes Parquet to Silver layer

Transformation:
- Flatten nested JSON structure
- Convert Kelvin to Celcius
- Deduplicate records (keep latest by ingestion_timestamp)
- Add quality flags
- Cpnvert to Parquet with snappy compression
- Parition by year/month/day

Input: s3://bucket/data/bronze/ (JSON)
Output: s3://bucket/data/silver/ (Parquet)
"""

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F
from pyspark.sql.types import *
from pyspark.sql.window import Window
from datetime import datetime


# Get job parameters
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_BUCKET'])

# Initialize Spark and Glue contexts
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Configuration
S3_BUCKET = args['S3_BUCKET']
BRONZE_PATH = f"s3://{S3_BUCKET}/data/bronze/"
SILVER_PATH = f"s3://{S3_BUCKET}/data/silver/"


print("="*80)
print("Bronze -> Silver Transformation")
print("="*80)
print(f"Source: {BRONZE_PATH}")
print(f"Target: {SILVER_PATH}")
print(f"Job started: {datetime.now().isoformat()}")
print("=" * 80)
print()

# Read BRONZE Data
print("Reading Bronze Layer....")

df_raw = spark.read \
    .option("multiline", "true") \
    .json(BRONZE_PATH)

initial_count = df_raw.count()
print(f"Initial record count: {initial_count:,}")
print()

# Extract & Flatten
print("Extracting and Flattening data...")

# Extract metadata - NOTE: typo in source JSON "tiomestamp" not "timestamp"
df_extracted = df_raw.select(
    F.col("ingestion_metadata.ingestion_tiomestamp")
        .cast("timestamp")
        .alias("ingestion_timestamp"),
    F.col("ingestion_metadata.city").alias("ingestion_city"),
    F.col("ingestion_metadata.source").alias("ingestion_source"),
    F.lit("v1").alias("schema_version"),
    
    # Explicitly select all raw_data fields instead of using raw_data.*
    F.col("raw_data.coord").alias("coord"),
    F.col("raw_data.weather").alias("weather"),
    F.col("raw_data.base").alias("base"),
    F.col("raw_data.main").alias("main"),
    F.col("raw_data.visibility").alias("visibility"),
    F.col("raw_data.wind").alias("wind"),
    F.col("raw_data.clouds").alias("clouds"),
    F.col("raw_data.dt").alias("dt"),
    F.col("raw_data.sys").alias("sys"),
    F.col("raw_data.timezone").alias("timezone"),
    F.col("raw_data.id").alias("id"),
    F.col("raw_data.name").alias("name"),
    F.col("raw_data.cod").alias("cod")
)

# Flatten nested weather data structure
df_flattened = df_extracted.select(
    # Metadata
    "ingestion_timestamp",
    "ingestion_city",
    "ingestion_source",
    "schema_version",
    
    # City information
    F.col("id").alias("city_id"),
    F.col("name").alias("city_name"),
    F.col("sys.country").alias("country_code"),

    # Coordinates
    F.col("coord.lon").alias("longitude"),
    F.col("coord.lat").alias("latitude"),
    
    # Temperature (already in Celsius in your data)
    F.col("main.temp").alias("temperature_celsius"),
    F.col("main.feels_like").alias("feels_like_celsius"),
    F.col("main.temp_min").alias("temp_min_celsius"),
    F.col("main.temp_max").alias("temp_max_celsius"),
    
    # Other weather metrics
    F.col("main.humidity").alias("humidity_percent"),
    F.col("main.pressure").alias("pressure_hpa"),
    F.col("main.sea_level").alias("sea_level_pressure_hpa"),
    F.col("main.grnd_level").alias("ground_level_pressure_hpa"),
    
    # Wind
    F.col("wind.speed").alias("wind_speed_mps"),
    F.col("wind.deg").alias("wind_direction_deg"),
    F.col("wind.gust").alias("wind_gust_mps"),
    
    # Clouds and visibility
    F.col("clouds.all").alias("cloudiness_percent"),
    F.col("visibility").alias("visibility_meters"),
    
    # Weather condition (array)
    F.col("weather").alias("weather_array"),

    # Timestamps
    F.from_unixtime(F.col("dt")).cast("timestamp").alias("observation_timestamp"),
    F.from_unixtime(F.col("sys.sunrise")).cast("timestamp").alias("sunrise_timestamp"),
    F.from_unixtime(F.col("sys.sunset")).cast("timestamp").alias("sunset_timestamp"),

    # Other
    F.col("timezone").alias("timezone_offset_seconds"),
    F.col("cod").alias("http_status_code")
)

print(f"Flattened to {len(df_flattened.columns)} columns")
print()

# Extract weather condition
print("Extracting weather condition...")

# Extract first element from weather array
df_weather = df_flattened.withColumn(
    "weather_id", F.col("weather_array").getItem(0).getField("id")
).withColumn(
    "weather_main", F.col("weather_array").getItem(0).getField("main")
).withColumn(
    "weather_description", F.col("weather_array").getItem(0).getField("description")
).drop("weather_array")

print("Weather conditons extracted")
print()

# Temperature is already in Celsius - no conversion needed
print("Temperature already in Celsius (no conversion needed)")

# Just use df_weather as-is
df_converted = df_weather

print()

# Data Quality Checks
print("Data quality checks...")

# Check for missing critical fields
df_quality = df_converted.withColumn(
    "has_missing_fields",
    (F.col("temperature_celsius").isNull()) |
    (F.col("humidity_percent").isNull()) |
    (F.col("pressure_hpa").isNull()) |
    (F.col("wind_speed_mps").isNull())
)

# Flags schema drift (placeholder - would need historical comparison)
df_quality = df_quality.withColumn(
    "schema_drift_detected", F.lit(False)
)

# Flag volume anomalies (placeholder - would need historical comparison)
df_quality = df_quality.withColumn(
    "is_volume_anomaly", F.lit(False)
)

# Calculate data quality score
df_quality = df_quality.withColumn(
    "data_quality_score",
    F.when(F.col("has_missing_fields"), 50.0)
    .when(F.col("schema_drift_detected"), 70.0)
    .otherwise(100.0)
)

# Count records with issues
missing_count = df_quality.filter(F.col("has_missing_fields") == True).count()
print(f"Records with missing fields: {missing_count} ({missing_count/df_quality.count()*100:.1f}%)")

# Deduplication
print("Deduplicating Records...")

window_spec = Window.partitionBy(
    "city_id",
    "observation_timestamp"
).orderBy(
    F.col("ingestion_timestamp").desc()
)

df_deduped = df_quality.withColumn(
    "row_number",
    F.row_number().over(window_spec)
).filter(F.col("row_number") == 1).drop("row_number")

deduped_count = df_deduped.count()
duplicates_removed = initial_count - deduped_count
print(f" Records before dedup: {initial_count:,}")
print(f" Records after dedup: {deduped_count:,}")
print(f" Duplicate records removed: {duplicates_removed:,}")
print()

# Add Partition Columns
print("Adding partition columns...")

df_final = df_deduped.withColumn(
    "year", F.year(F.col("observation_timestamp"))
).withColumn(
    "month", F.month(F.col("observation_timestamp"))
).withColumn(
    "day", F.dayofmonth(F.col("observation_timestamp"))
)

print("Partition columns added : year, month, day")
print()

# Quality Summary
print("Data Quality Summary:")
print(f" Total records: {df_final.count():,}")
print(f" Records with missing data: {missing_count:,}")

avg_quality = df_final.agg(F.mean("data_quality_score")).collect()[0][0]
print(f" Average Data Quality Score: {avg_quality:.1f}/100")

# Sample Statistics
temp_stats = df_final.agg(
    F.min("temperature_celsius").alias("min_temp"),
    F.max("temperature_celsius").alias("max_temp"),
    F.avg("temperature_celsius").alias("avg_temp")
).collect()[0]

print(f" Temperature range: {temp_stats['min_temp']:.1f} - {temp_stats['max_temp']:.1f} Celsius")
print(f" Average temperature: {temp_stats['avg_temp']:.1f} Celsius")
print()

# Write to Silver Layer

print(f" Writing to Silver layer:{SILVER_PATH}")
print("Format: Parquet with snappy compression")
print(" Partition by year/month/day")
print()

# Write as Parquet with partitioning
df_final.write \
    .mode("append") \
    .partitionBy("year", "month", "day") \
    .parquet(SILVER_PATH, compression = "snappy")

print(" Write Completed..")
print()

# Storage Optimization info
print("Storage Optimization:")
print(" JSON -> Parquet conversion")
print(" Snappy compression enabled")
print(" Expected storage savings: ~70%")
print()

# Summary
print("="*80)
print(" Transformation Complete")
print("="*80)
print(f"✅ Processed {initial_count:,} raw records")
print(f"✅ Removed {duplicates_removed:,} duplicates")
print(f"✅ Wrote {deduped_count:,} clean records to Silver")
print(f"✅ Average quality score: {avg_quality:.1f}/100")
print("=" * 80)

# Commit job
job.commit()