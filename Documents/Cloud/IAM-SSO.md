---
title: AWS IAM Identity Center (SSO) Setup
date: 2026-03-31
category: [Cloud Infrastructure, Security & Identity Management]
tags:
  [
    aws,
    security,
    yubikey,
    fido2,
    homelab,
    dual-stack,
    aws-cli,
    sso,
    iam,
    identity-center,
    webauthn,
  ]
status: Deployed / Verified
---

# Engineering Log: AWS IAM Identity Center (SSO) Setup

## Objective

To establish a secure, enterprise-grade authentication architecture for managing AWS cloud resources. This implementation deprecates the use of long-lived, permanent IAM user access keys for administrative tasks in favor of short-lived, automatically rotating STS credentials governed by AWS IAM Identity Center (formerly AWS SSO).

This infrastructure will securely house the cloud backend for the ForRad application and future integrations with the local routing and virtualization environment.

---

## Architecture & Security Standards

    Authentication Method: AWS IAM Identity Center via AWS CLI v2.

    MFA Hardware: FIDO2 / WebAuthn standard enforced via Yubikey. Physical "User Presence" (touching the key) is required for token generation, ensuring maximum resistance against remote polling and phishing.

    Network Routing: Utilized the modern AWS Dual-stack Access Portal URL, ensuring the CLI can route authentication traffic over both IPv6 and IPv4 networks simultaneously.

    Authorization: Least-privilege applied via Permission Sets, mapping the human identity to specific, temporary IAM Roles rather than permanent user policies.

## Implementation Steps

1. Account Organization
   Deployed AWS Organizations from the root account to enable centralized policy management.

   Enabled IAM Identity Center in the us-east-1 (N. Virginia) region.

2. Identity & Access Provisioning
   Provisioned a primary human administrative User in the Identity Center directory.

   Registered a physical Yubikey as the primary MFA device.

   Created a Permission Set granting AdministratorAccess with a defined session duration limit.

   Mapped the human User to the primary AWS Account and bound it to the AdministratorAccess Permission Set.

3. Local Environment Configuration
   Removed legacy plain-text access keys from ~/.aws/credentials to prevent accidental exposure or credential harvesting.

Configured the local AWS CLI utilizing the interactive SSO setup (aws configure sso), inputting the following parameters:

    Session Name: homelab

    Start URL: https://ssoins-[ID].portal.us-east-1.app.aws (Dual-stack endpoint)

    Region: us-east-1

4.  Verification & Daily Workflow
    Authentication is now handled entirely through the browser and hardware token. To initiate a secure session, the following command is executed:

        Bash
        aws sso login --profile default

    Note: The CLI opens the default browser, prompts for the Yubikey touch authorization, and securely drops temporary STS credentials into the local environment.

To verify the active assumed role and session ARN:

    Bash
    aws sts get-caller-identity
