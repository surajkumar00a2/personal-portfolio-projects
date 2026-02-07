#!/bin/bash

echo "=========================================="
echo "SCHEDULING GLUE CRAWLER"
echo "=========================================="
echo ""

# Update crawler to run daily at 4 AM (after all Glue jobs complete)
aws glue update-crawler \
  --name weather-data-lake-crawler \
  --schedule "cron(0 4 * * ? *)"

echo "✓ Crawler scheduled to run daily at 4:00 AM UTC"
echo ""
echo "Pipeline timing:"
echo "  00:00 - Lambda ingestion"
echo "  00:30 - Bronze→Silver"
echo "  00:35 - Silver→Gold"
echo "  04:00 - Crawler (discover new partitions)"
echo ""
echo "✅ Crawler scheduled"
