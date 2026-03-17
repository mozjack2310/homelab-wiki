---
title: Escaping the WSL Routing Matrix
date: 2026-03-17
category: [Networking, Troubleshooting, SSH]
tags: [CCNA, WSL2, RHEL, OpenWrt]
status: Resolved
---

# Engineering Log: Escaping the WSL Routing Matrix

## Objective

Establish secure, public-key SSH authentication between a local **RHEL (WSL2)** environment and a physical **OpenWrt router**, eliminating password reliance.

---

## 1. The Baseline (The Control)

Verified the physical network, OpenWrt SSH daemon, and firewall rules were healthy by successfully connecting from the **Windows host via PowerShell**.

- **Result:** Isolated the fault domain entirely to the WSL virtual network/Linux instances.

## 2. The Symptoms

- **Error:** RHEL threw a hard `Connection refused (TCP RST)` when attempting to reach the router's IP (`192.168.10.1`).
- **Observation:** Server-side OpenSSH debug logs (`logread -f`) showed absolute silence.
- **Conclusion:** Packets were being dropped or misrouted before hitting the physical interface.

## 3. The Investigation

1.  **Client-side Logging:** Ran `ssh -v` to confirm the correct **ED25519** key was being offered.
2.  **Process Check:** Discovered the WSL environment was trapping traffic locally due to rogue OpenSSH server processes.
3.  **Routing Table Analysis:** Executed `ip route` to track the packet lifecycle.

## 4. The Root Cause

> [!IMPORTANT]
> **Subinterface Conflict**
> A leftover `eth0.10` subinterface—an artifact from **CCNA 200-301 v1.1** lab practice—was hijacking the `192.168.10.0/24` subnet. RHEL was acting as its own gateway, dropping SSH traffic into a black hole instead of routing it to the physical gateway.

## 5. The Resolution

- **Cleanup:** Destroyed the persistent subinterface blueprint using `nmcli connection delete`.
- **Cleanup:** `nmcli connection delete [interface_name]`
- **Permissions:** Secured OpenWrt directory permissions:
  - `chmod 700 ~/.ssh`
  - `chmod 600 ~/.ssh/authorized_keys`
- **Verification:** Successfully authenticated using the custom ED25519 public key.

---

**Tags:** #Networking #CCNA #OpenWrt #WSL2 #SSH
