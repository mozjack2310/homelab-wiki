---
title: Provisioning a Redis Cache via Terraform on Proxmox
date: 2026-04-11
category: [Cloud Infrastructure, Automation & Scripting, Backend]
tags: [infrastructure, terraform, proxmox, redis, backend, deployment]
status: Deployed
---

# Engineering Log: Provisioning a Redis Cache via Terraform on Proxmox

## Objective

**Deploying a secure, lightweight Debian 13 LXC container to cache weather API payloads.**

---

## Architectural Overview

To mitigate API rate limits for the ForRad dashboard (specifically historical data from Open-Meteo and live NWS feeds), a Redis cache was deployed on the backend subnet. This prevents the RHEL API proxy from hammering external endpoints on every frontend refresh.

## Infrastructure as Code (Terraform)

The container was provisioned using the `telmate/proxmox` provider.

**Key Configurations & Bug Fixes:**

- **Provider Versioning:** Upgraded to `v3.0.2-rc07` and implemented `pm_minimum_permission_check = false` to bypass a known Proxmox 9 `VM.Monitor` permission bug.
- **LXC Nesting:** Set `nesting = true` in the `features` block. This was required because Debian 13 (Trixie) uses a strict version of `systemd` that crashes with credential errors during the `agetty` console spawn if run in a completely unprivileged, un-nested environment.

## Security Configuration

Zero-trust practices were maintained on the internal network:

- `bind 0.0.0.0` implemented to allow cross-subnet traffic from the RHEL proxy.
- `protected-mode yes` maintained.
- `requirepass` configured to enforce authentication before any key-value pairs can be read or written.
