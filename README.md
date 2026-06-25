# 🏡 Homelab Wiki

Welcome to my Homelab Wiki! This repository serves as the central documentation hub for my home network infrastructure, server deployments, hardware projects, and ongoing IT studies.

## 📑 Table of Contents

- [Architecture & Hardware](#architecture--hardware)
- [Network Configuration](#network-configuration)
- [Virtualization & Compute](#virtualization--compute)
- [Active Projects](#active-projects)
- [Certification Studies](#certification-studies)
- [Scripts & Automation](#scripts--automation)

---

## 🖥️ Architecture & Hardware

An overview of the physical gear powering the lab:

### Servers & Compute

- **Main Host:** Dell Optiplex 7060
- **Microcontrollers/SBCs:** Raspberry Pi, Raspberry Pi Pico (W)

### Networking & Peripherals

- **Switches:** Netgear GS108T Managed Switch
- **NICs:** Intel I350-T4 (Passed through to pfSense)
- **Peripherals:** HP LaserJet Pro M402dn
- **Security:** YubiKey (Hardware MFA)

---

## 🌐 Network Configuration

Details on routing, switching, and security.

- **Firewall/Router:** pfSense (Virtualized via Proxmox)
- **Switching & Redundancy:** Link Aggregation (LACP) configured between the Proxmox host and the Netgear GS108T (`bond0` interface for failover).
- **VLANs:**
  - `VLAN 10`: Management
  - `VLAN 20`: Servers / VMs
  - `VLAN 30`: IoT / Smart Home Devices
  - `VLAN 40`: Printers (Dedicated for HP LaserJet)
- **Monitoring:** SNMP monitoring via Zabbix.

---

## 📦 Virtualization & Compute

Documentation on my hypervisor setup and core virtual machines.

- **Hypervisor:** Proxmox VE
- **Core VMs / Containers:**
  - `pfSense` - Core edge routing and firewall.
  - `RHEL 10` - Docker and Podman container host running custom bridge networks.
  - `GNS3-Server` - Emulation environment for networking labs.
  - `Zabbix` - Infrastructure monitoring and SNMP hardware tracking.
- **Cloud & Access:** AWS IAM Identity Center utilizing short-lived STS credentials and YubiKey-backed MFA for secure cloud management.

---

## 🚀 Active Projects

Current software development and hardware builds running in the lab.

### ForRad Weather Dashboard

A custom-built weather telemetry and monitoring application focusing on Birmingham meteorological data.

- **Architecture:** Containerized via Docker/Podman on RHEL 10 utilizing a custom bridge network.
- **Stack:** Next.js (Frontend), Python/Flask (Proxy/Backend), Redis.
- **Integrations:** National Weather Service (NWS) API, NOMADS, NEXRAD radar layers, GFS, and HRRR model data.
- **Status:** Active Development

### Physical NOC Display

A live dashboard for monitoring severe weather and network status.

- **Hardware:** Raspberry Pi Pico, MatrixPortal M4, LED Matrix Panels
- **Status:** Building/Testing

### RF Analysis & Smart Home Security

Investigating local radio frequencies and analyzing sensor data.

- **Tools:** Raspberry Pi, GNU Radio software, RTL-SDR
- **Target:** Vivint smart home sensor analysis

---

## 📚 Certification Studies

### Cisco CCNA 200-301 v1.1

Lab environments and notes for my CCNA studies, targeting an exam attempt by Summer 2026.

- **Platform:** GNS3 with Cisco IOU images alongside physical Netgear/Cisco hardware practice.
- **Focus Areas:** Switching, Trunking, VLAN routing, Network Automation.
- _Note: Any legacy "ghost VLAN" sub-interfaces found in lab configs are artifacts from previous Network+ practice scripts._

---

## ⚙️ Scripts & Automation

A collection of scripts used to manage the lab infrastructure and pull data. My primary terminal environment and workflow is built on Ubuntu/RHEL via WSL2.

- **Python (Netmiko):** Scripts for backing up and configuring switch infrastructure.
- **Python (Boto3):** Cloud integrations and data fetching.

---

_This wiki is a living document and is updated as the lab evolves._
