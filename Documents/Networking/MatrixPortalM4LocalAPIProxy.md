---
title: Adafruit MatrixPortal M4 Local API Proxy
date: 2026-04-06
category:
  [
    Embedded Systems,
    Microcontrollers,
    Networking,
    Security,
    Enterprise Linux,
    Backend/Proxy,
    Python,
  ]
tags:
  [
    ESP32,
    MatrixPortal M4,
    Red Hat Enterprise Linux,
    Python,
    Flask,
    API Proxy,
    Local,
    Proxy,
    Weather,
    Temperature,
    systemd,
    SELinux,
    pfSense,
    VLAN,
    OpenWrt,
    Homelab,
  ]
status: Deployed / Verified
---

# Engineering Log: Adafruit MatrixPortal M4 Local API Proxy

## 📌 Project Objective

To display dynamic data (temperature) on a 64x32 LED matrix using an Adafruit MatrixPortal M4. To bypass the ESP32 Wi-Fi coprocessor's memory limitations with HTTPS/TLS handshakes, a local HTTP API gateway was engineered to intercept, decrypt, and serve the data over plain-text HTTP.

## 🏗️ Architecture Stack

_Hardware_: Adafruit MatrixPortal M4, 64x32 LED Matrix, ESP32 Wi-Fi Coprocessor.

_Network_: OpenWrt AP (2.4GHz IoT VLAN) -> Netgear GS110TP -> pfSense Firewall -> RHEL 10 VM.

_Software/OS_: CircuitPython (Frontend), Enterprise Linux 10, Python 3 / Flask (Backend Proxy), systemd (Service Management).

---

## 🛠️ Troubleshooting Log & Technical Roadblocks

## 1. The HTTPS Memory Crash (TLS Handshake Failure)

Symptom: The MatrixPortal would crash with an Out of Memory error when attempting to fetch data directly from public internet APIs.

Root Cause: The ESP32 chip lacks the onboard RAM to process modern, heavy HTTPS/TLS certificate handshakes. When forced to read the encrypted binary data, it choked.

Solution: Built a Python Flask proxy server (weather_proxy.py) hosted on a local RHEL VM. The RHEL server handles the heavy HTTPS encryption with the public API, parses the JSON, and serves a lightweight, unencrypted HTTP endpoint to the MatrixPortal.

## 2. ESP32 "Soft Reboot" Hang (ESP32 not responding)

Symptom: After saving code in VS Code, the main processor would restart, but the script would hang when trying to initialize the Wi-Fi chip.

Root Cause: The tiny capacitors on the board hold a charge, keeping the ESP32 trapped in its previous network socket state during a soft reboot.

Solution: Implemented a "Pre-Flight" hardware reset script in code.py. By cycling the board.ESP_RESET pin (cutting power, holding it low for 0.5s, then releasing and waiting 3 seconds), the coprocessor is forced into a clean slate on every single boot.

## 3. The TCP Keep-Alive Trap

Symptom: The board successfully connected to Wi-Fi and the RHEL terminal logged a 200 OK request, but the MatrixPortal still timed out and froze.

Root Cause: Flask uses HTTP Keep-Alive by default, leaving the connection open after sending data. The embedded Adafruit library expects the server to immediately close the connection and hangs while waiting for the "goodbye" packet.

Solution: Injected a specific header into the Flask response to force an immediate disconnect: response.headers['Connection'] = 'close'.

## 4. Layer 3 Routing / VLAN Segmentation Block

Symptom: The board could reach the public internet, but requests to the local RHEL proxy (192.168.1.101) timed out entirely. No traffic reached the RHEL logs.

Root Cause: The OpenWrt AP was bridged to an isolated IoT VLAN (IOT_VLAN210). The pfSense firewall had a strict top-down rule blocking all traffic from IOT_VLAN210 to private RFC1918 subnets.

Solution: [Insert pfSense screenshot here] Engineered a targeted firewall rule in pfSense allowing the specific ESP32 IP (192.168.210.15) to communicate exclusively with the RHEL VM IP on TCP port 5000. Placed this rule above the general block rule to punch a secure hole through the subnets.

## 5. systemd vs. SELinux (203/EXEC Permission Denied)

Symptom: When converting the Flask script to a background systemd service, it immediately failed with a status=203/EXEC error.

Root Cause: Enterprise Linux utilizes SELinux, which strictly forbids background daemons from executing binaries located inside personal user directories (/home/...). Moving the files to /opt/ created an ownership mismatch between the root-created virtual environment and the sysbldr service user.

Solution: 1. Migrated the project directory to /opt/weather-proxy/. 2. Transferred folder ownership back to the service user: sudo chown -R user:user /opt/weather-proxy. 3. Reset the SELinux security contexts to match the /opt/ directory policies: sudo restorecon -Rv /opt/weather-proxy.

## 6. Upstream API Outages (502 / 504 Gateway Errors)

Symptom: The MatrixPortal would sporadically crash and freeze when the Open-Meteo backend database experienced high load or timeout issues, resulting in the RHEL proxy throwing a generic 500 Internal Server Error to the embedded device.

Root Cause: The original Python proxy blindly attempted to parse the JSON response. When Open-Meteo returned HTML error pages (502/504) instead of JSON, the requests library triggered a fatal Python KeyError or ConnectionError.

Solution: Hardened the weather_proxy.py script with explicit status code validation (if response.status_code != 200:) and a global try/except block. Instead of crashing, the proxy now catches upstream timeouts, suppresses the Python exception, and serves a clean {"temperature": "ERR"} payload to the MatrixPortal. This allows the hardware to fail gracefully, wait 60 seconds, and retry without requiring a manual hardware reboot.

---

## 📄 Next Steps / Future Enhancements:

- **Implement Server-Side Caching:** Update the Flask `weather_proxy.py` to cache the Open-Meteo API response for 5–10 minutes. This will prevent the RHEL server from rate-limiting against the public API if the Matrix board enters a rapid reboot loop.

- **Homelab Metrics Integration:** Expand the Flask API gateway with new routes (e.g., `/proxmox-stats` or `/pfsense-wan`). The RHEL server can securely authenticate with local infrastructure APIs and serve lightweight hardware metrics (CPU load, WAN bandwidth) to the Matrix display.

- **Auto-Start at Boot:** Verify that the RHEL VM is configured in Proxmox to auto-start on boot, ensuring the `weatherproxy.service` daemon comes online automatically after a host power cycle.

- **Multi-Screen Cycling:** Update the CircuitPython `code.py` script to fetch from multiple local proxy endpoints, rotating the display between the weather, homelab alerts, and time every 30 seconds.

---
