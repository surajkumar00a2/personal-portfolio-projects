import sys
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.sql.functions import from_json, col, to_timestamp
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, IntegerType

# Initialize contexts
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Connect kisnesis stream
kinesis_stream_name = "StockDataStream"
kinesis_region = "us-east-1"

df_raw = spark.readStream \
    .format("kinesis") \
    .option("streamName", kinesis_stream_name) \
    .option("region", kinesis_region) \
    .option("initialPosition", "TRIM_HORIZON") \
    .load()

# Print schema
df_raw.printSchema()

# Convert to string
df_string = df_raw.selectExpr("CAST(value AS STRING)")

# Print
df_string.show()

# Convert to JSON
jsonSchema = StructType([
    StructType("symbol", StringType(), True),
    StructType("timestamp", StringType(), True),
    StructType("open", DoubleType(), True),
    StructType("high", DoubleType(), True),
    StructType("low", DoubleType(), True),
    StructType("close", DoubleType(), True),
    StructType("volume", IntegerType(), True)
])

# Parse JSON
df_parsed = df_string.select(from_json(col("data"), jsonSchema).alias("record")).select("record.*")

# Transform columns
df_transformed = df_parsed.wihtColumn("event_time", to_timestamp(col("timestamp"), "yyyy-MM-dd HH:mm:ss"))

# Write to S3
query = df_transformed.writeStream \
    .format("parquet") \
    .option("checkpointLocation", "s3://stock-data-pipeline-suraj/raw/stock_data/") \
    .option("path", "s3://stock-data-pipeline-suraj/processed/stock_data/") \
    .ouptutMode("append") \
    .start()
    
# Wait for the query to finish
query.awaitTermination()