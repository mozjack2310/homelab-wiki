---
title: Enterprise Data Pipeline: Keyless AWS S3 Uploads via Roles Anywhere
date: 2026-04-10
category: [Cloud Infrastructure, Cloud Architecture, Automation & Scripting, Backend]
tags: [AWS, IAM Roles Anywhere, PKI, OpenSSL, Python, Boto3, Systemd, RHEL 10, Homelab, Security, Networking, Cloud, Automation, Backend]
status: Resolved
---

# Engineering Log: Enterprise Data Pipeline: Keyless AWS S3 Uploads via Roles Anywhere

## Objective

This log documents the transition from a local homelab weather API (ForRad) to a secure, automated cloud archiving pipeline. To avoid the security vulnerabilities of long-term AWS IAM Access Keys, this architecture utilizes **AWS IAM Roles Anywhere**. By establishing a custom Public Key Infrastructure (PKI), the local RHEL 10 server securely authenticates with AWS using short-lived, certificate-backed sessions to upload JSON payloads to an S3 bucket.

---

## Architectural Overview

- **Source:** Local ForRad Flask API Proxy serving weather telemetry.
- **Compute:** Red Hat Enterprise Linux (RHEL 10) VM.
- **Security:** Custom OpenSSL Root CA and x509 v3 Client Certificates.
- **Cloud Bridge:** AWS IAM Roles Anywhere (Trust Anchor & Profile).
- **Storage:** AWS S3 Bucket (`forrad-nws-data-archive-bg`) with least-privilege IAM policies.
- **Automation:** Python (`boto3`, `requests`) triggered via `systemd` timers.

---

## Phase 1: PKI & AWS Roles Anywhere Setup

### 1. The Trust Anchor (Root CA)

- A custom Root Certificate Authority was generated locally on the RHEL server and uploaded to AWS Roles Anywhere to establish the Trust Anchor.

### 2. The Client Certificate (The x509 V3 Trap)

- AWS Roles Anywhere strictly requires **x509 Version 3** certificates with specific extensions. Default OpenSSL CSR signing often fails this validation. To resolve "Insufficient Certificate" errors from AWS, the client certificate was explicitly signed with the following `client.ext` metadata:

**INI Configuration**

```ini
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature
extendedKeyUsage = clientAuth
```

The signing command utilized:

**Bash Command**

```bash
openssl x509 -req -in client.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out client.pem -days 365 -sha256 -extfile client.ext
```

### 3. The IAM Role & Policy

An IAM Role (ForRad-RolesAnywhere-S3-Role) was configured to trust the Roles Anywhere service. A custom policy was attached to allow specific read/write access, ensuring files could be managed and metadata could be read without granting full bucket access:

**JSON Policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowForRadScriptToReadWrite",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::forrad-nws-data-archive-bg/*"
    },
    {
      "Sid": "AllowListBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::forrad-nws-data-archive-bg"
    }
  ]
}
```

---

## Phase 2: Python Automation Pipeline

The local ~/.aws/config was configured to use the aws_signing_helper to automatically assume the role using the local client.pem.

A Python script (test_s3.py) was written to fetch live data from the local API and vault it to S3 entirely in memory, eliminating local disk I/O. Note: ContentType='application/json' is critical so the AWS console natively renders the files rather than forcing a binary download.

**Python Script**

```python
import boto3
import requests
import json
from datetime import datetime

# 1. Authenticate using Roles Anywhere profile
session = boto3.Session(profile_name='roles-anywhere')
s3 = session.client('s3')

# 2. Configuration
bucket_name = 'forrad-nws-data-archive-bg'
api_url = 'http://localhost:5000/current_weather' # Local Flask Proxy

print(f"Fetching live data from {api_url}...")

try:
    # 3. Fetch live API data
    response = requests.get(api_url, timeout=10)
    response.raise_for_status()
    weather_data = response.json()

    # 4. Generate timestamped filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_name = f"forrad_data_{timestamp}.json"

    # 5. Upload to S3 with correct ContentType metadata
    print(f"Uploading as {file_name} to {bucket_name}...")
    s3.put_object(
        Bucket=bucket_name,
        Key=file_name,
        Body=json.dumps(weather_data),
        ContentType='application/json'
    )

    print("SUCCESS! Enterprise pipeline execution complete.")

except Exception as e:
    print(f"CRITICAL FAILURE: {e}")

```

---

## Phase 3: Enterprise Scheduling with Systemd

- To ensure resilient, background execution that survives reboots and logs cleanly (avoiding the silent failure trap of cron), the script is orchestrated via systemd.

**The Service (/etc/systemd/system/forrad-s3-upload.service)**

```ini, TOML
[Unit]
Description=ForRad Weather Data S3 Uploader
After=network.target

[Service]
Type=oneshot
User=sysbldr1220711
Environment="HOME=/home/sysbldr1220711"
ExecStart=/usr/bin/python3 /home/sysbldr1220711/test_s3.py
StandardOutput=journal
StandardError=journal
```

**The Timer (/etc/systemd/system/forrad-s3-upload.timer)**

- Configured to execute at the top of every hour.
  **INI, TOML**

```ini, TOML
[Unit]
Description=Timer for ForRad S3 Uploader

[Timer]
OnCalendar=*-*-* *:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

## Phase 4: Verification

- To check the schedule and monitor live executions

**Bash**

```bash
# Check next scheduled run
systemctl list-timers | grep forrad

# Monitor live execution logs
sudo journalctl -u forrad-s3-upload.service -f
```

---

## Next Steps

With the infrastructure manually verified and the automated pipeline active, the next phase will involve translating the AWS console configurations (Trust Anchor, Profiles, Roles, and S3 Bucket) into Infrastructure as Code (IaC) using Terraform for reproducible deployment.

---
