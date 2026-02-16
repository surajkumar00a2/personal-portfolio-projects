#!/bin/bash

echo "=========================================="
echo "MANUAL EXECUTION COMMANDS"
echo "=========================================="
echo ""

LAMBDA_FUNCTION=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `weather-ingestion`)].FunctionName' --output text)
BUCKET_NAME=$(cat config/bucket-name.txt 2>/dev/null || echo "YOUR-BUCKET")

echo "1. Run Lambda ingestion manually:"
echo "   aws lambda invoke --function-name $LAMBDA_FUNCTION response.json && cat response.json | jq ."
echo ""

echo "2. Run Glue transformation jobs manually:"
echo "   # Bronze → Silver"
echo "   aws glue start-job-run --job-name bronze-to-silver-transform"
echo ""
echo "   # Silver → Gold"
echo "   aws glue start-job-run --job-name silver-to-gold-aggregations"
echo ""

echo "3. Run Glue crawler manually:"
CRAWLER=$(aws glue get-crawlers --query 'Crawlers[?contains(Name, `weather`)].Name' --output text | head -1)
echo "   aws glue start-crawler --name $CRAWLER"
echo ""

echo "4. Check data in S3:"
echo "   aws s3 ls s3://$BUCKET_NAME/data/bronze/ --recursive --human-readable"
echo "   aws s3 ls s3://$BUCKET_NAME/data/silver/ --recursive --human-readable"
echo "   aws s3 ls s3://$BUCKET_NAME/data/gold/ --recursive --human-readable"
echo ""

echo "5. Query with Athena:"
echo "   aws athena start-query-execution \\"
echo "     --query-string 'SELECT * FROM weather_silver LIMIT 10;' \\"
echo "     --result-configuration OutputLocation=s3://$BUCKET_NAME/athena-results/"
echo ""

echo "=========================================="
