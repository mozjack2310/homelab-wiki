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

### Networking Gear

- **Switches:** Netgear Managed/Unmanaged Switches

- **NICs:** Intel I350-T4 (Passed through to pfSense)

---

## 🌐 Network Configuration

Details on routing, switching, and security.

- **Firewall/Router:** pfSense (Virtualized via Proxmox)

- **VLANs:**
  - `VLAN 10`: Management
  - `VLAN 20`: Servers / VMs
  - `VLAN 30`: IoT / Smart Home Devices

- _(Link to detailed network topology diagram or IPAM spreadsheet here)_

---

## 📦 Virtualization & Compute

Documentation on my hypervisor setup and core virtual machines.

- **Hypervisor:** Proxmox VE

- **Core VMs / Containers:**
  - `pfSense` - Core edge routing and firewall.
  - `RHEL-Lab` - Red Hat Enterprise Linux instances for testing and configuration.
  - `GNS3-Server` - Emulation environment for networking labs.

---

## 🚀 Active Projects

Current software development and hardware builds running in the lab.

### ForRad Weather Dashboard

A custom-built weather monitoring application.

- **Stack:** Next.js, TypeScript
- **Integrations:** National Weather Service (NWS) API, Esri API
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

Lab environments and notes for my CCNA studies.

- **Platform:** GNS3 with Cisco IOU images

- **Focus Areas:** Switching, Trunking, VLAN routing, Network Automation.

- _(Link to dedicated CCNA study notes or lab configurations)_

---

## ⚙️ Scripts & Automation

A collection of scripts used to manage the lab infrastructure and pull data.

- **Python (Netmiko):** Scripts for backing up and configuring switch infrastructure.

- **Python (Boto3):** Cloud integrations and data fetching.

- _(Link to scripts directory)_

---

_This wiki is a living document and is updated as the lab evolves._
