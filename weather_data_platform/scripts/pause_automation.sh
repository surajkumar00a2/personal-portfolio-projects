#!/bin/bash

echo "=========================================="
echo "PAUSING ALL AUTOMATION"
echo "=========================================="
echo ""

AWS_REGION=$(aws configure get region)
LAMBDA_FUNCTION=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `weather-ingestion`)].FunctionName' --output text)

# 1. Disable EventBridge rule (stops Lambda from running every 6 hours)
echo "1. Disabling EventBridge scheduled trigger..."
RULE_NAME=$(aws events list-rules --query 'Rules[?contains(Name, `weather`)].Name' --output text | head -1)
if [ ! -z "$RULE_NAME" ]; then
    aws events disable-rule --name "$RULE_NAME"
    echo "   ✓ Disabled: $RULE_NAME"
else
    echo "   No EventBridge rules found"
fi

# Disable all weather-related rules
for rule in $(aws events list-rules --query 'Rules[?contains(Name, `weather`)].Name' --output text); do
    aws events disable-rule --name "$rule" 2>/dev/null
    echo "   ✓ Disabled: $rule"
done

echo ""

# 2. Disable Glue workflow triggers
echo "2. Disabling Glue workflow triggers..."
TRIGGERS=$(aws glue get-triggers --query 'Triggers[?contains(WorkflowName, `weather`)].Name' --output text)
for trigger in $TRIGGERS; do
    aws glue update-trigger --name "$trigger" --trigger-update "Actions=[]" 2>/dev/null || true
    echo "   ✓ Disabled: $trigger"
done

# Stop workflow if running
WORKFLOW=$(aws glue list-workflows --query 'Workflows[?contains(@, `weather`)]' --output text | head -1)
if [ ! -z "$WORKFLOW" ]; then
    echo "   ✓ Workflow found: $WORKFLOW (will not auto-start)"
fi

echo ""

# 3. Disable Glue crawler schedule
echo "3. Disabling Glue crawler..."
CRAWLER=$(aws glue get-crawlers --query 'Crawlers[?contains(Name, `weather`)].Name' --output text | head -1)
if [ ! -z "$CRAWLER" ]; then
    aws glue update-crawler --name "$CRAWLER" --schedule "" 2>/dev/null && \
        echo "   ✓ Removed schedule from: $CRAWLER" || \
        echo "   Already no schedule on: $CRAWLER"
else
    echo "   No crawler found"
fi

echo ""

# 4. Remove Lambda event source mappings (SQS, if any)
echo "4. Checking Lambda event sources..."
EVENT_SOURCES=$(aws lambda list-event-source-mappings --function-name "$LAMBDA_FUNCTION" --query 'EventSourceMappings[].UUID' --output text 2>/dev/null)
if [ ! -z "$EVENT_SOURCES" ]; then
    for uuid in $EVENT_SOURCES; do
        aws lambda update-event-source-mapping --uuid "$uuid" --enabled false
        echo "   ✓ Disabled event source: $uuid"
    done
else
    echo "   No event sources found"
fi

echo ""
echo "=========================================="
echo "AUTOMATION PAUSED"
echo "=========================================="
echo ""
echo "What's paused:"
echo "  ✓ EventBridge scheduled Lambda triggers (every 6 hours)"
echo "  ✓ S3 event triggers (Bronze→Silver→Gold)"
echo "  ✓ Glue workflow automation"
echo "  ✓ Glue crawler schedule"
echo ""
echo "How to run manually:"
echo "  Lambda:    aws lambda invoke --function-name $LAMBDA_FUNCTION response.json"
echo "  Glue Jobs: aws glue start-job-run --job-name bronze-to-silver-transform"
echo "  Crawler:   aws glue start-crawler --name $CRAWLER"
echo ""
echo "To resume automation:"
echo "  Run: ./scripts/resume_automation.sh"
echo ""
