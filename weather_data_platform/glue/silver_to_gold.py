"""
Silver to Gold Transformation
==============================

Creates curated analytics tables from Silver layer:
1. weather_daily_summary - Daily weather aggregations per city
2. quality_scorecard_daily - Daily data quality metrics
3. reliability_trends_weekly - Weekly reliability trends

Input:  s3://bucket/data/silver/ (Parquet)
Output: s3://bucket/data/gold/ (Aggregated Parquet)
"""

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F
from pyspark.sql.window import Window
from datetime import datetime

# INITIALIZE

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_BUCKET'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

S3_BUCKET = args['S3_BUCKET']
SILVER_PATH = f"s3://{S3_BUCKET}/data/silver/"
GOLD_PATH = f"s3://{S3_BUCKET}/data/gold/"

print("=" * 80)
print("SILVER → GOLD TRANSFORMATION")
print("=" * 80)
print(f"Source: {SILVER_PATH}")
print(f"Target: {GOLD_PATH}")
print(f"Job started: {datetime.now().isoformat()}")
print("=" * 80)
print()

# READ SILVER DATA

print("Reading Silver layer...")

df_silver = spark.read.parquet(SILVER_PATH)

record_count = df_silver.count()
print(f" Total records in Silver: {record_count:,}")
print()

# Show schema
print("Silver schema:")
df_silver.printSchema()
print()

# TABLE 1: WEATHER DAILY SUMMARY

print("=" * 80)
print("CREATING TABLE 1: weather_daily_summary")
print("=" * 80)
print()

print("Aggregating daily weather metrics...")

# Create date column
df_daily_weather = df_silver.withColumn(
    "date", F.to_date(F.col("observation_timestamp"))
)

# Group by city and date
df_daily_agg = df_daily_weather.groupBy("city_name", "date").agg(
    # Temperature aggregations
    F.round(F.avg("temperature_celsius"), 2).alias("avg_temperature_celsius"),
    F.round(F.min("temperature_celsius"), 2).alias("min_temperature_celsius"),
    F.round(F.max("temperature_celsius"), 2).alias("max_temperature_celsius"),
    
    # Feels like temperature
    F.round(F.avg("feels_like_celsius"), 2).alias("avg_feels_like_celsius"),
    
    # Humidity
    F.round(F.avg("humidity_percent"), 2).alias("avg_humidity_percent"),
    F.min("humidity_percent").alias("min_humidity_percent"),
    F.max("humidity_percent").alias("max_humidity_percent"),
    
    # Pressure
    F.round(F.avg("pressure_hpa"), 2).alias("avg_pressure_hpa"),
    
    # Wind
    F.round(F.avg("wind_speed_mps"), 2).alias("avg_wind_speed_mps"),
    F.round(F.max("wind_speed_mps"), 2).alias("max_wind_speed_mps"),
    F.round(F.avg("wind_gust_mps"), 2).alias("avg_wind_gust_mps"),
    
    # Cloudiness
    F.round(F.avg("cloudiness_percent"), 2).alias("avg_cloudiness_percent"),
    
    # Visibility
    F.round(F.avg("visibility_meters"), 0).alias("avg_visibility_meters"),
    
    # Counts
    F.count("*").alias("observations_count"),
    
    # Most common weather condition
    F.first("weather_main").alias("dominant_weather_condition"),
    
    # Time range
    F.min("observation_timestamp").alias("first_observation_time"),
    F.max("observation_timestamp").alias("last_observation_time")
)

# Add partition columns
df_daily_weather_final = df_daily_agg \
    .withColumn("year", F.year(F.col("date"))) \
    .withColumn("month", F.month(F.col("date")))

weather_summary_count = df_daily_weather_final.count()
print(f"   Created {weather_summary_count:,} daily summaries")
print()

# Show sample
print("   Sample data:")
df_daily_weather_final.orderBy(F.col("date").desc()).show(5, truncate=False)

# Write to Gold
gold_weather_path = f"{GOLD_PATH}weather_daily_summary/"
print(f"Writing to: {gold_weather_path}")

df_daily_weather_final.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet(gold_weather_path, compression="snappy")

print(" weather_daily_summary written")
print()

# TABLE 2: QUALITY SCORECARD DAILY

print("=" * 80)
print("CREATING TABLE 2: quality_scorecard_daily")
print("=" * 80)
print()

print("Aggregating quality metrics...")

# Create date column
df_quality_daily = df_silver.withColumn(
    "date", F.to_date(F.col("observation_timestamp"))
)

# Aggregate quality metrics by date
df_quality_agg = df_quality_daily.groupBy("date").agg(
    # Volume metrics
    F.count("*").alias("total_ingestions"),
    F.sum(F.when(F.col("has_missing_fields") == False, 1).otherwise(0)).alias("successful_ingestions"),
    F.sum(F.when(F.col("has_missing_fields") == True, 1).otherwise(0)).alias("failed_ingestions"),
    
    # Quality issues
    F.sum(F.when(F.col("has_missing_fields") == True, 1).otherwise(0)).alias("records_with_missing_fields"),
    F.sum(F.when(F.col("schema_drift_detected") == True, 1).otherwise(0)).alias("schema_changes_detected"),
    F.sum(F.when(F.col("is_volume_anomaly") == True, 1).otherwise(0)).alias("volume_anomalies_detected"),
    
    # Quality scores
    F.round(F.avg("data_quality_score"), 2).alias("avg_data_quality_score"),
    F.min("data_quality_score").alias("min_data_quality_score"),
    F.max("data_quality_score").alias("max_data_quality_score")
)

# Calculate derived quality scores
df_quality_scores = df_quality_agg.withColumn(
    "completeness_score",
    F.round((F.col("successful_ingestions") / F.col("total_ingestions") * 100), 2)
).withColumn(
    "consistency_score",
    F.when(F.col("schema_changes_detected") > 0, 0.0).otherwise(100.0)
).withColumn(
    "timeliness_score",
    F.lit(95.0)  # Placeholder - would calculate from actual ingestion times
).withColumn(
    "availability_score",
    F.lit(100.0)  # Placeholder - would calculate from API success rate
)

# Overall quality score (weighted average)
df_quality_final = df_quality_scores.withColumn(
    "overall_quality_score",
    F.round(
        (F.col("completeness_score") * 0.4 +
         F.col("consistency_score") * 0.3 +
         F.col("timeliness_score") * 0.2 +
         F.col("availability_score") * 0.1),
        2
    )
)

# Add partition columns
df_quality_final = df_quality_final \
    .withColumn("year", F.year(F.col("date"))) \
    .withColumn("month", F.month(F.col("date")))

quality_scorecard_count = df_quality_final.count()
print(f"   Created {quality_scorecard_count:,} daily quality scorecards")
print()

# Show sample
print("   Sample data:")
df_quality_final.select(
    "date", "total_ingestions", "overall_quality_score", 
    "completeness_score", "consistency_score"
).orderBy(F.col("date").desc()).show(5, truncate=False)

# Write to Gold
gold_quality_path = f"{GOLD_PATH}quality_scorecard_daily/"
print(f"Writing to: {gold_quality_path}")

df_quality_final.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet(gold_quality_path, compression="snappy")

print("  quality_scorecard_daily written")
print()

# TABLE 3: RELIABILITY TRENDS WEEKLY

print("=" * 80)
print("CREATING TABLE 3: reliability_trends_weekly")
print("=" * 80)
print()

print("Aggregating weekly trends...")

# Add week start date
df_weekly = df_silver.withColumn(
    "week_start_date", F.date_trunc("week", F.col("observation_timestamp"))
)

# Aggregate by week
df_weekly_agg = df_weekly.groupBy("week_start_date").agg(
    # Quality metrics
    F.round(F.avg("data_quality_score"), 2).alias("avg_quality_score"),
    F.min("data_quality_score").alias("min_quality_score"),
    F.max("data_quality_score").alias("max_quality_score"),
    
    # Schema changes
    F.sum(F.when(F.col("schema_drift_detected") == True, 1).otherwise(0)).alias("schema_changes"),
    
    # Volume anomalies
    F.sum(F.when(F.col("is_volume_anomaly") == True, 1).otherwise(0)).alias("volume_anomalies"),
    
    # Total observations
    F.count("*").alias("total_observations"),
    
    # Unique cities
    F.countDistinct("city_name").alias("unique_cities")
)

# Calculate reliability indicators
df_weekly_final = df_weekly_agg.withColumn(
    "api_availability_percent", F.lit(99.5)  # Placeholder
).withColumn(
    "schema_stable", F.when(F.col("schema_changes") == 0, True).otherwise(False)
).withColumn(
    "volume_stable", F.when(F.col("volume_anomalies") == 0, True).otherwise(False)
).withColumn(
    "total_alerts_generated",
    F.col("schema_changes") + F.col("volume_anomalies")
)

# Add partition columns
df_weekly_final = df_weekly_final \
    .withColumn("year", F.year(F.col("week_start_date"))) \
    .withColumn("week", F.weekofyear(F.col("week_start_date")))

weekly_trends_count = df_weekly_final.count()
print(f"   Created {weekly_trends_count:,} weekly trend records")
print()

# Show sample
print("   Sample data:")
df_weekly_final.select(
    "week_start_date", "total_observations", "avg_quality_score", 
    "schema_stable", "volume_stable"
).orderBy(F.col("week_start_date").desc()).show(5, truncate=False)

# Write to Gold
gold_trends_path = f"{GOLD_PATH}reliability_trends_weekly/"
print(f"Writing to: {gold_trends_path}")

df_weekly_final.write \
    .mode("overwrite") \
    .partitionBy("year", "week") \
    .parquet(gold_trends_path, compression="snappy")

print("  reliability_trends_weekly written")
print()

# SUMMARY

print("=" * 80)
print("GOLD LAYER SUMMARY")
print("=" * 80)
print(f"weather_daily_summary:      {weather_summary_count:,} records")
print(f"quality_scorecard_daily:    {quality_scorecard_count:,} records")
print(f"reliability_trends_weekly:  {weekly_trends_count:,} records")
print("=" * 80)
print()

print("All tables written to:")
print(f"   {GOLD_PATH}")
print()

print("=" * 80)
print("TRANSFORMATION COMPLETE")
print("=" * 80)

job.commit()