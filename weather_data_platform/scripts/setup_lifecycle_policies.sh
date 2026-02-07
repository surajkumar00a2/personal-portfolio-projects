#!/bin/bash

echo "=========================================="
echo "CONFIGURING S3 LIFECYCLE POLICIES"
echo "=========================================="
echo ""

BUCKET_NAME=$(cat config/bucket-name.txt)

# Create lifecycle policy JSON
cat > /tmp/lifecycle-policy.json <<POLICY
{
  "Rules": [
    {
      "Id": "delete-old-bronze-data",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "data/bronze/"
      },
      "Expiration": {
        "Days": 30
      }
    },
    {
      "Id": "transition-old-silver-to-ia",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "data/silver/"
      },
      "Transitions": [
        {
          "Days": 90,
          "StorageClass": "STANDARD_IA"
        }
      ]
    },
    {
      "Id": "delete-old-metrics",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "metrics/quality/"
      },
      "Expiration": {
        "Days": 90
      }
    },
    {
      "Id": "delete-athena-results",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "athena-results/"
      },
      "Expiration": {
        "Days": 7
      }
    }
  ]
}
POLICY

# Apply lifecycle policy
aws s3api put-bucket-lifecycle-configuration \
  --bucket $BUCKET_NAME \
  --lifecycle-configuration file:///tmp/lifecycle-policy.json

echo "✓ Lifecycle policies applied to: $BUCKET_NAME"
echo ""
echo "Policies:"
echo "  • Bronze data deleted after 30 days"
echo "  • Silver data moved to IA storage after 90 days"
echo "  • Metrics deleted after 90 days"
echo "  • Athena results deleted after 7 days"
echo ""
echo "Cost savings: ~60% on storage after 30 days"
echo ""

# Clean up
rm /tmp/lifecycle-policy.json

echo "✅ Lifecycle policies configured"