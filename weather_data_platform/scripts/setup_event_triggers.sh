#!/bin/bash

echo "=========================================="
echo "SETTING UP EVENT-DRIVEN GLUE TRIGGERS"
echo "=========================================="
echo ""

BUCKET_NAME=$(cat config/bucket-name.txt)
AWS_REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Deploy Glue trigger Lambda first
echo "0. Deploying Glue trigger Lambda..."
./scripts/deploy_glue_trigger_lambda.sh
echo ""

# Enable EventBridge notifications on S3 bucket
echo "1. Enabling EventBridge notifications on S3 bucket..."
aws s3api put-bucket-notification-configuration \
  --bucket $BUCKET_NAME \
  --notification-configuration '{
    "EventBridgeConfiguration": {}
  }'

echo "✓ S3 EventBridge enabled"
echo ""

# Create EventBridge rule for Bronze data
echo "2. Creating EventBridge rule for Bronze data..."
aws events put-rule \
  --name weather-bronze-data-arrived \
  --event-pattern '{
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": {
        "name": ["'$BUCKET_NAME'"]
      },
      "object": {
        "key": [{
          "prefix": "data/bronze/"
        }]
      }
    }
  }' \
  --state ENABLED \
  --description "Trigger when new Bronze data arrives"

echo "✓ EventBridge rule created"
echo ""

# Add Lambda permission for EventBridge
echo "3. Adding Lambda invoke permission for EventBridge..."
aws lambda add-permission \
  --function-name glue-job-trigger \
  --statement-id AllowEventBridgeInvoke \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:$AWS_REGION:$ACCOUNT_ID:rule/weather-bronze-data-arrived \
  2>/dev/null || echo "  Permission already exists"

echo "✓ Lambda permission added"
echo ""

# Add target to trigger Lambda (which triggers Glue)
echo "4. Configuring EventBridge target (Lambda for Bronze→Silver)..."
aws events put-targets \
  --rule weather-bronze-data-arrived \
  --targets '[
    {
      "Id": "1",
      "Arn": "arn:aws:lambda:'$AWS_REGION':'$ACCOUNT_ID':function:glue-job-trigger"
    }
  ]'

echo "✓ Bronze→Silver trigger configured"
echo ""

# Create rule for Silver data (to trigger Gold)
echo "5. Creating EventBridge rule for Silver data..."
aws events put-rule \
  --name weather-silver-data-arrived \
  --event-pattern '{
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": {
        "name": ["'$BUCKET_NAME'"]
      },
      "object": {
        "key": [{
          "prefix": "data/silver/"
        }]
      }
    }
  }' \
  --state ENABLED \
  --description "Trigger when new Silver data arrives"

echo "✓ EventBridge rule created"
echo ""

# Add Lambda permission for Silver rule
echo "6. Adding Lambda invoke permission for Silver rule..."
aws lambda add-permission \
  --function-name glue-job-trigger \
  --statement-id AllowEventBridgeInvokeSilver \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:$AWS_REGION:$ACCOUNT_ID:rule/weather-silver-data-arrived \
  2>/dev/null || echo "  Permission already exists"

echo "✓ Lambda permission added"
echo ""

# Add target for Silver→Gold
echo "7. Configuring EventBridge target (Lambda for Silver→Gold)..."
aws events put-targets \
  --rule weather-silver-data-arrived \
  --targets '[
    {
      "Id": "1",
      "Arn": "arn:aws:lambda:'$AWS_REGION':'$ACCOUNT_ID':function:glue-job-trigger"
    }
  ]'

echo "✓ Silver→Gold trigger configured"
echo ""

echo "=========================================="
echo "EVENT-DRIVEN PIPELINE CONFIGURED"
echo "=========================================="
echo ""
echo "Pipeline flow:"
echo "  1. Lambda ingestion writes to Bronze"
echo "  2. S3 → EventBridge → Lambda (glue-job-trigger)"
echo "  3. Lambda starts Bronze→Silver Glue job"
echo "  4. Glue writes to Silver"
echo "  5. S3 → EventBridge → Lambda (glue-job-trigger)"
echo "  6. Lambda starts Silver→Gold Glue job"
echo ""
echo "Test it:"
echo "  aws lambda invoke --function-name weather-ingestion response.json"
echo "  (Wait 2-3 minutes, Glue jobs will start automatically)"
echo ""
echo "View logs:"
echo "  aws logs tail /aws/lambda/glue-job-trigger --follow"
echo ""
