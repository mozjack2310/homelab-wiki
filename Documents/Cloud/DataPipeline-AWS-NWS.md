---
title: "Cloud Data Engineering: Serverless NWS Weather Pipeline"
date: 2026-03-28
category: [Cloud Architecture, Automation & Scripting]
tags:
  [
    aws,
    s3,
    iam,
    python,
    boto3,
    api-integration,
    serverless,
    national-weather-service,
  ]
status: Deployed / Verified
---

# Engineering Log: "Cloud Data Engineering: Serverless NWS Weather Pipeline"

## Objective

Automate the extraction of active weather alerts from the National Weather Service API and securely ingest them into an AWS S3 data vault for downstream dashboard consumption.

---

## 1. Architecture Overview

- **Source:** National Weather Service (NWS) API (api.weather.gov)

- **Compute:** Local RHEL Python Environment

- **Storage:** _AWS S3_ (Blob Storage)

- **Security:** _AWS IAM_ (Zero-Trust Service Account)

---

## 2. AWS Infrastructure (Day 0 Configuration)

#### **A. S3 Storage Bucket**

- Created a standard general-purpose bucket (sysbldr-nws-dashboard-data).

- **Security** : "Block all public access" enabled to prevent unauthorized internet reads.

#### **B. IAM Service Account (nws-data-bot)**

- Created a dedicated programmatic user with no console access.
- Secured via a custom inline JSON policy enforcing the Principle of Least Privilege.
- The bot is strictly limited to PutObject actions in the specific target bucket.

## Inline Policy (NwsDataUploadOnly):

**JSON**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowBotToPutWeatherAlerts",
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": "arn:aws:s3:::sysbldr-nws-dashboard-data/*"
    }
  ]
}
```

#### **C. Budget Tripwire**

- Configured AWS Budgets with a strict $1.00 monthly threshold.

- Alerts route to primary email at 85%, 100%, and forecasted 100% of the threshold.

---

## 3. The Automation Script (weather_pipeline.py)

This script requires the boto3 and requests libraries. It relies on the AWS CLI (aws configure) to silently resolve the IAM Access Keys from the local environment.

```python
    import json
    import requests
    import boto3
    from datetime import datetime

## ==========================================
# CONFIGURATION
## ==========================================

BUCKET_NAME = 'sysbldr-nws-dashboard-data'

## NWS strictly requires a custom User-Agent

NWS_HEADERS = {
'User-Agent': '(HomelabWeatherDashboard, sysbldr1220711@example.com)',
'Accept': 'application/geo+json'
}

## Target: Active alerts for Alabama

NWS_URL = 'https://api.weather.gov/alerts/active?area=AL'

## ==========================================
# EXECUTION
## ==========================================

    def push_weather_to_s3():
        try:
            print("📡 Fetching live data from the National Weather Service...")
            response = requests.get(NWS_URL, headers=NWS_HEADERS, timeout=10)
            response.raise_for_status()
            weather_data = response.json()

            alert_count = len(weather_data.get('features', []))
            print(f"✅ Successfully pulled {alert_count} active alerts for Alabama.")

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            file_name = f"nws_alabama_alerts_{timestamp}.json"

            print(f"☁️  Uploading {file_name} to S3 bucket: '{BUCKET_NAME}'...")

            s3_client = boto3.client('s3')
            s3_client.put_object(
                Bucket=BUCKET_NAME,
                Key=file_name,
                Body=json.dumps(weather_data, indent=2),
                ContentType='application/json'
            )

            print(f"🚀 Success! Data is secured in AWS.")

        except Exception as e:
            print(f"\n❌ Pipeline Error: {e}")

    if __name__ == "__main__":
        push_weather_to_s3()
```

---

## 4. Execution & Verification

### Execution:

Run the pipeline from the activated virtual environment:

```Bash
    source .venv/bin/activate
    python weather_pipeline.py
```

---

### Verification:

Confirm the timestamped .json file is present in the AWS S3 Console. Note that clicking the public object URL will result in an AccessDenied error by design. Data must be viewed via a Pre-Signed URL or an authenticated frontend API call.

---
