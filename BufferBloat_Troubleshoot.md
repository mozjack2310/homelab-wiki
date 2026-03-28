---
title: Mitigating Bufferbloat with pfSense and FQ_CODEL
date: 2026-03-27
category: Networking, pfSense, Traffic Shaper, Limiters
tags: FQ_CODEL, Traffic Shaping, pfSense, bufferbloat, latency, CCNA 200-301 v1.1
status: Resolved
---

# Engineering Log: Mitigating Bufferbloat with pfSense and FQ_CODEL

## Objective

**Goal:** Eliminate high latency spikes (+200ms) under heavy load on a highly asymmetrical residential ISP connection (Spectrum).

**Method:** Implement FQ_CODEL using pfSense Limiters to shift queue management away from the ISP modem's unmanaged buffers and onto the local firewall.

---

## 1. Hardware Prerequisites

For `dummynet` (the underlying limiter framework) to process packets correctly, hardware offloading must be disabled on the virtualized pfSense NICs.

- **Navigate to:** `System` > `Advanced` > `Networking`
- **Check:** Disable hardware checksum offload
- **Check:** Disable hardware TCP segmentation offload
- **Check:** Disable hardware large receive offload

## 2. Setting up the Root Limiters (The Scheduler)

The Root Limiters define the absolute maximum bandwidth ceiling and apply the Fair Queuing scheduler to separate traffic flows.

- **Navigate to:** `Firewall` > `Traffic Shaper` > `Limiters`
- **Create Download Root:**
  - **Name:** `Download`
  - **Bandwidth:** `390` `Mbit/s` _(Calculated at ~90-95% of reliable max throughput)_
  - **Queue length:** _Leave Blank_ (Do not use 1000 slots)
  - **Scheduler:** `FQ_CODEL`
- **Create Upload Root:**
  - **Name:** `Upload`
  - **Bandwidth:** `7500` `Kbit/s` _(Use Kbit/s to bypass pfSense whole-number rounding for strict upload limits)_
  - **Queue length:** _Leave Blank_
  - **Scheduler:** `FQ_CODEL`

## 3. Setting up the Child Queues (The AQM Algorithm)

The Child Queues run the Active Queue Management algorithm to gracefully drop packets before buffers overflow.

- **Create Download Child:**
  - **Name:** `Download_FQ`
  - **Queue Management Algorithm:** `CoDel`
  - **Enable ECN:** `Checked`
- **Create Upload Child:**
  - **Name:** `Upload_FQ`
  - **Queue Management Algorithm:** `CoDel`
  - **Enable ECN:** `Checked`

## 4. Firewall Floating Rule

Traffic must be directed to the _Child Queues_, not the Root Limiters.

- **Navigate to:** `Firewall` > `Rules` > `Floating`
- **Action:** `Match`
- **Interface:** `WAN`
- **Direction:** `out`
- **Address Family:** `IPv4` _(Clone for IPv6 if deployed later)_
- **Protocol:** `Any`
- **Advanced > In / Out pipe:**
  - **In Pipe (Left):** `Upload_FQ` _(Outbound WAN traffic)_
  - **Out Pipe (Right):** `Download_FQ` _(Inbound WAN traffic)_

## 5. The Resolution - Applying Changes

**CRITICAL:** Limiters will not engage on active connections.

1. Apply changes in the Firewall Rules interface.
2. Navigate to `Diagnostics` > `States` > `Reset States`.
3. Check **Reset the firewall state table** and click Reset.

---
