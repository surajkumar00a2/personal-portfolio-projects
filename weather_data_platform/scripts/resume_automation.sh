#!/bin/bash

echo "=========================================="
echo "RESUMING AUTOMATION"
echo "=========================================="
echo ""

AWS_REGION=$(aws configure get region)

# 1. Enable EventBridge rules
echo "1. Enabling EventBridge rules..."
for rule in $(aws events list-rules --query 'Rules[?contains(Name, `weather`)].Name' --output text); do
    aws events enable-rule --name "$rule"
    echo "   ✓ Enabled: $rule"
done

echo ""

# 2. Re-enable Glue crawler schedule
echo "2. Re-enabling Glue crawler schedule..."
CRAWLER=$(aws glue get-crawlers --query 'Crawlers[?contains(Name, `weather`)].Name' --output text | head -1)
if [ ! -z "$CRAWLER" ]; then
    aws glue update-crawler --name "$CRAWLER" --schedule "cron(0 4 * * ? *)"
    echo "   ✓ Crawler will run daily at 04:00 UTC"
fi

echo ""

# 3. Re-enable event source mappings
echo "3. Re-enabling Lambda event sources..."
LAMBDA_FUNCTION=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `weather-ingestion`)].FunctionName' --output text)
EVENT_SOURCES=$(aws lambda list-event-source-mappings --function-name "$LAMBDA_FUNCTION" --query 'EventSourceMappings[].UUID' --output text 2>/dev/null)
if [ ! -z "$EVENT_SOURCES" ]; then
    for uuid in $EVENT_SOURCES; do
        aws lambda update-event-source-mapping --uuid "$uuid" --enabled true
        echo "   ✓ Enabled event source: $uuid"
    done
fi

echo ""
echo "=========================================="
echo "AUTOMATION RESUMED"
echo "=========================================="
echo ""
echo "Active schedules:"
echo "  • Lambda: Every 6 hours (00:00, 06:00, 12:00, 18:00 UTC)"
echo "  • Glue: Triggered by S3 events"
echo "  • Crawler: Daily at 04:00 UTC"
echo ""
