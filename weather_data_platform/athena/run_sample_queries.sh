#!/bin/bash

echo "=========================================="
echo "ATHENA SAMPLE QUERIES"
echo "=========================================="
echo ""

BUCKET_NAME=$(cat config/bucket-name.txt)
ATHENA_OUTPUT="s3://$BUCKET_NAME/athena-results/"

echo "Query results will be saved to: $ATHENA_OUTPUT"
echo ""

# Query 1: Quality scorecard
echo "1. Running quality scorecard query..."
aws athena start-query-execution \
  --query-string "SELECT date, overall_quality_score, total_ingestions FROM weather_data_lake.gold_quality_scorecard_daily WHERE year=2026 AND month=1 ORDER BY date DESC LIMIT 10;" \
  --result-configuration OutputLocation=$ATHENA_OUTPUT \
  --query-execution-context Database=weather_data_lake

sleep 2

# Query 2: Weather summary
echo "2. Running weather summary query..."
aws athena start-query-execution \
  --query-string "SELECT city_name, date, avg_temperature_celsius FROM weather_data_lake.gold_weather_daily_summary WHERE year=2026 AND month=1 ORDER BY date DESC LIMIT 10;" \
  --result-configuration OutputLocation=$ATHENA_OUTPUT \
  --query-execution-context Database=weather_data_lake

sleep 2

# Query 3: Check views
echo "3. Running view query..."
aws athena start-query-execution \
  --query-string "SELECT * FROM weather_data_lake.v_latest_weather;" \
  --result-configuration OutputLocation=$ATHENA_OUTPUT \
  --query-execution-context Database=weather_data_lake

echo ""
echo "✅ Queries submitted!"
echo "View results in Athena Console: https://console.aws.amazon.com/athena/"