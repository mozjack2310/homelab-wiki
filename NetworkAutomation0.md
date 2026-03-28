---
title: Network Automation CCNA First Attempt
date: 2026-03-28
category: Networking, Automation, VLANs
tags: networking, automation, python, CML, Cisco, CCNA 200-301 v1.1, vlans, SSH, scripting
status: Deployed / Verified
---

# Engineering Log:

## Objective

Automate the provisioning of the core homelab VLAN architecture across Cisco IOS devices using Python and the netmiko library.

---

## 1. Prerequisites

1.  Python Environment: A dedicated .venv with netmiko installed.

2.  CML Bridge: The virtual Cisco IOL switch must be connected to an External Connector node configured for Bridge: (bridge0) to allow physical network access.

3.  Day 0 Switch Configuration: The target switch must have an IP address and SSH enabled.

## 2. Day 0 SSH Configuration (Cisco CLI)

Before Python can connect, the switch requires RSA keys and VTY line access:

    Plaintext
    configure terminal
    ip domain name homelab.local
    crypto key generate rsa  ! (Choose 2048 bits)
    ip ssh version 2

    username admin privilege 15 secret cisco

    line vty 0 4
    login local
    transport input ssh
    exit

    interface vlan 1
    ip address 192.168.1.150 255.255.255.0
    no shutdown
    exit

## 3.The Automation Script (cml_configblast.py)

This script establishes an SSH connection, pushes the VLAN database to the running configuration, and verifies the deployment.

Python
from netmiko import ConnectHandler
from datetime import datetime

    # 1. DEFINE THE TARGET DEVICE
        cisco_switch = {
            'device_type': 'cisco_ios',
            'host': '192.168.1.150',  # Bridged IP of the CML node
            'username': 'admin',
            'password': 'cisco',
        }

    # 2. DEFINE THE CONFIGURATION PAYLOAD
        vlan_commands = [
            'vlan 10',
            'name DATA_10',
            'vlan 30',
            'name DATA_WIFI_30',
            'vlan 40',
            'name GUEST_40',
            'vlan 55',
            'name MGMT_55',
            'vlan 210',
            'name IOT_DMZ_210',
            'exit'
        ]

    # 3. EXECUTE THE AUTOMATION
        def push_vlans():
            print(f"\n[{datetime.now().strftime('%H:%M:%S')}] 🚀 Initiating SSH connection to {cisco_switch['host']}...")

            try:
                net_connect = ConnectHandler(**cisco_switch)
                print(f"[{datetime.now().strftime('%H:%M:%S')}] ✅ Successfully logged into {net_connect.find_prompt()}")

                print(f"[{datetime.now().strftime('%H:%M:%S')}] ⚙️ Pushing VLAN architecture to the running-config...")
                output = net_connect.send_config_set(vlan_commands)

                print("\n--- SWITCH OUTPUT ---")
                print(output)
                print("---------------------\n")

                print(f"[{datetime.now().strftime('%H:%M:%S')}] 🔍 Verifying VLAN database...")
                verify_output = net_connect.send_command('show vlan brief')
                print(verify_output)

                net_connect.disconnect()
                print(f"\n[{datetime.now().strftime('%H:%M:%S')}] 🏁 Disconnected. Infrastructure deployed successfully.")

            except Exception as e:
                print(f"\n❌ AUTOMATION FAILED. Error details: {e}")

        if __name__ == "__main__":
            push_vlans()

## 4. Execution

Run the script from the activated virtual environment:

    Bash
    source .venv/bin/activate
    python cml_configblast.py

---
