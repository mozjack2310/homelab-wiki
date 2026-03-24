---
title: End-to-End 802.1Q VLAN Trunking - pfSense to OpenWrt (swconfig)
date: 2026-03-23
category: Networking & Security
tags: CCNA 200-301 v1.1, pfSense, OpenWrt, VLAN, 802.1Q, Netgear, swconfig, Homelab
status: Deployed / Verified
---

# Engineering Log: OpenWrt "Dumb AP" VLAN Trunking

## Overview

**Hardware Stack:** Dell Optiplex (Proxmox/pfSense) -> Netgear GS108Tv3 (Core) / Netgear GS110TPv3 (Access) -> TP-Link Archer A7 v5 (OpenWrt).

**Objective:** Successfully pass an 802.1Q tagged VLAN (VLAN 210) from a virtualized pfSense router, through physical Netgear managed switches, and broadcast it as an isolated SSID on an OpenWrt access point utilizing the older `swconfig` architecture.

---

## 1. pfSense Firewall & DHCP (The Brain)

- **Create the VLAN:** Assign VLAN 210 to the parent physical interface (e.g., `igb1`).
- **Enable DHCP:** Go to **Services > DHCP Server > IOT_VLAN210** and enable the pool.
- **Set the DNS:** _Crucial Step._ In the DHCP server settings, assign public DNS (e.g., `8.8.8.8`) OR proceed to Firewall rules to allow local DNS.
- **Firewall Rules (Top-Down Execution):**
  - **Rule 1 (Allow DNS):** Pass | IPv4 UDP/TCP | Source: `IOT_VLAN210 net` | Dest: `IOT_VLAN210 Address` | Port: 53. _(Only needed if not using public DNS)._
  - **Rule 2 (The DMZ Block):** Block | IPv4 \* | Source: `IOT_VLAN210 net` | Dest: `Private_IPs` alias (RFC1918 subnets).
  - **Rule 3 (Allow Internet):** Pass | IPv4 \* | Source: `IOT_VLAN210 net` | Dest: `Any`.

## 2. Netgear Switches (The Highway)

- Ensure the end-to-end 802.1Q trunk is contiguous across the core and access switches.
- In **VLAN Membership**, mark the uplink port to pfSense and the downlink port to the OpenWrt AP with a **`T`** (Tagged) for VLAN 210.

---

## 3. OpenWrt Hardware Switch (The swconfig Bouncer)

_Because the Archer A7 uses `swconfig`, the physical switch chip must be programmed before the software bridge can see the tags._

1.  Navigate to **Network > Switch**.
2.  Add a new VLAN row for ID `210`.
3.  Set the physical **LAN port** connected to the Netgear switch to **Tagged**.
4.  Set the **CPU (eth0)** port to **Tagged**.
5.  Save & Apply. This generates the `eth0.210` interface.

---

## 4. OpenWrt Software Bridge & Wireless

1.  **Create the Bridge:** Navigate to **Network > Devices**. Add a new `Bridge device` (e.g., `br-iot`).
2.  **Assign the Port:** In the Bridge Ports dropdown, select **only** `eth0.210`.
3.  **Disable Snooping:** Under the Advanced tab for this bridge, uncheck **Enable multicast snooping** to prevent DHCP unicast packet drops.
4.  **Bind the Wireless:** Navigate to **Network > Wireless**. Assign the IoT SSID to the unmanaged `IOT_210` interface. Use strictly WPA2-PSK (Force CCMP/AES) for maximum IoT compatibility.
5.  **The Firewall Zone:** Navigate to **Network > Interfaces**. Edit `IOT_210`, go to Firewall Settings, and assign it to the default green `lan` zone. _(This ensures OpenWrt acts purely as a transparent Layer 2 AP and does not block return DHCP traffic)._
6.  **Reboot:** Reboot the OpenWrt router to commit the hardware switch mappings.

---

## 5. The Resolution

- **Cleanup:**
  - Remove any orphaned `br-lan.210` or software-only VLAN interfaces that were created before configuring the hardware `swconfig` chip.
  - Uncheck "Disassociate on Low Acknowledgement" in the advanced wireless settings to prevent cheap IoT antennas from being prematurely kicked off the network.
  - "Forget" the Wi-Fi network on client devices to clear any cached WPA3 security profiles after downgrading the SSID to WPA2.

- **Verification:**
  - **Layer 2 (Netgear):** Verify the switch's MAC Address Table shows the client MAC address learned on the OpenWrt port, and the pfSense MAC address learned on the uplink port for VLAN 210.
  - **Layer 3 (pfSense):** Check **Status > DHCP Leases** and **Diagnostics > ARP Table** to confirm the router successfully completed the D.O.R.A. process and mapped the IP to the client's MAC.
  - **Client Side:** Connect a device to the SSID and verify it pulls an IP in the target subnet, registers the gateway as the DNS server, and successfully routes out to the WAN (External IP).

---
