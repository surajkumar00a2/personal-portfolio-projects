#!/bin/bash

echo "=========================================="
echo "DEPLOYMENT VERIFICATION"
echo "=========================================="
echo ""

BUCKET_NAME=$(cat config/bucket-name.txt)
AWS_REGION=$(aws configure get region)

# Check Lambda
echo "1. Lambda Function:"
LAMBDA_STATUS=$(aws lambda get-function --function-name weather-ingestion 2>&1)
if echo "$LAMBDA_STATUS" | grep -q "FunctionName"; then
    echo "   ✅ weather-ingestion exists"
else
    echo "   ❌ weather-ingestion not found"
fi
echo ""

# Check Glue Jobs
echo "2. Glue Jobs:"
BRONZE_SILVER=$(aws glue get-job --job-name bronze-to-silver-transform 2>&1)
if echo "$BRONZE_SILVER" | grep -q "Name"; then
    echo "   ✅ bronze-to-silver-transform exists"
else
    echo "   ❌ bronze-to-silver-transform not found"
fi

SILVER_GOLD=$(aws glue get-job --job-name silver-to-gold-aggregations 2>&1)
if echo "$SILVER_GOLD" | grep -q "Name"; then
    echo "   ✅ silver-to-gold-aggregations exists"
else
    echo "   ❌ silver-to-gold-aggregations not found"
fi
echo ""

# Check Glue Workflow
echo "3. Glue Workflow:"
WORKFLOW=$(aws glue get-workflow --name weather-data-pipeline 2>&1)
if echo "$WORKFLOW" | grep -q "Name"; then
    echo "   ✅ weather-data-pipeline exists"
else
    echo "   ❌ weather-data-pipeline not found"
fi
echo ""

# Check S3 Data
echo "4. S3 Data:"
BRONZE_COUNT=$(aws s3 ls s3://$BUCKET_NAME/data/bronze/ --recursive | wc -l)
SILVER_COUNT=$(aws s3 ls s3://$BUCKET_NAME/data/silver/ --recursive | grep parquet | wc -l)
GOLD_COUNT=$(aws s3 ls s3://$BUCKET_NAME/data/gold/ --recursive | grep parquet | wc -l)
METRICS_COUNT=$(aws s3 ls s3://$BUCKET_NAME/metrics/quality/ --recursive | grep parquet | wc -l)

echo "   Bronze files: $BRONZE_COUNT"
echo "   Silver files: $SILVER_COUNT"
echo "   Gold files: $GOLD_COUNT"
echo "   Metrics files: $METRICS_COUNT"
echo ""

# Check Athena Tables
echo "5. Athena Tables:"
TABLES=$(aws glue get-tables --database-name weather_data_lake 2>&1)
if echo "$TABLES" | grep -q "silver_weather_data"; then
    echo "   ✅ silver_weather_data exists"
else
    echo "   ❌ silver_weather_data not found - run DDLs"
fi

if echo "$TABLES" | grep -q "gold_weather_daily_summary"; then
    echo "   ✅ gold_weather_daily_summary exists"
else
    echo "   ❌ gold_weather_daily_summary not found - run DDLs"
fi
echo ""

# Check CloudWatch Dashboard
echo "6. CloudWatch Dashboard:"
DASHBOARD=$(aws cloudwatch get-dashboard --dashboard-name data-quality-monitoring 2>&1)
if echo "$DASHBOARD" | grep -q "DashboardName"; then
    echo "   ✅ data-quality-monitoring exists"
else
    echo "   ⚠️  data-quality-monitoring not found (optional)"
fi
echo ""

# Summary
echo "=========================================="
echo "VERIFICATION COMPLETE"
echo "=========================================="
echo ""

if [ "$BRONZE_COUNT" -gt 0 ] && [ "$SILVER_COUNT" -gt 0 ]; then
    echo "✅ Platform is operational!"
else
    echo "⚠️  Platform deployed but no data yet. Run:"
    echo "   aws lambda invoke --function-name weather-ingestion response.json"
fi
echo ""
echo "View resources:"
echo "  Lambda: https://console.aws.amazon.com/lambda/home?region=$AWS_REGION#/functions/weather-ingestion"
echo "  Glue: https://console.aws.amazon.com/glue/home?region=$AWS_REGION#/v2/etl-configuration/workflows"
echo "  Athena: https://console.aws.amazon.com/athena/home?region=$AWS_REGION"
echo "  S3: https://s3.console.aws.amazon.com/s3/buckets/$BUCKET_NAME"
echo ""
