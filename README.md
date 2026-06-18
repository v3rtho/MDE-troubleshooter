# MDE Troubleshooter

A PowerShell WPF GUI tool for analyzing and troubleshooting Microsoft Defender for Endpoint (MDE) on Windows endpoints. Provides a centralized view of security configuration, event logs, performance data, and diagnostic actions — all in one interface.

> **Disclaimer:** Script provided as-is. Use at your own risk. No guarantees or warranty provided. Always test in a non-production environment first.

---

## Requirements

- Windows 10 / Windows 11 (Windows Server 2019+)
- PowerShell 5.1 or later
- **Administrator privileges** (required — script will not run without them)
- Microsoft Defender Antivirus (not compatible with third-party AV)
- MDE onboarded endpoint (required for SENSE logs and Troubleshooting Mode features)

---

## How to Run

```powershell
# Run as Administrator
powershell.exe -ExecutionPolicy Bypass -File .\testFormV2.ps1
```

Or right-click the script and select **Run with PowerShell** (as Administrator).

---

## Features

### Defender AV
Overview of the local Defender AV configuration, loaded on startup from `Get-MpComputerStatus` and `Get-MpPreference`.

| Section | Details |
|---|---|
| Version Information | Engine, Product, Service, NIS engine versions, running mode, computer state |
| Service Status | AM service, Antivirus, Antispyware, NIS enabled status, Virtual Machine flag, Computer ID |
| Real-Time Protection | RTP, OnAccess, Behavior Monitor, IOAV, Tamper Protection status and source |
| Scan Information | Full and Quick scan age, start/end times |
| Protection Settings | Cloud block level, block at first seen, cloud timeout, quarantine days, file hash computation, device control |
| Additional Information | Signature fallback order, NIS signature last updated, last quick scan source |

Includes a **Refresh** button to re-query all values without restarting the tool.

---

### Attack Surface Reduction (ASR)
- View all 19 ASR rules with their current status (Enabled / Audit / Warning / Not Enabled)
- Filter rules by status
- View **per-rule ASR exclusions** from the registry (`HKLM:\SOFTWARE\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR`)
- Open the local **Exploit Protection XML** configuration

---

### Exclusions
- View all Defender AV exclusions: **Path**, **Extension**, **Process**, and **IP Address**
- Searchable and filterable DataGrid
- **Registry Key Information**:
  - `ManagedDefenderProductType` — management channel (Intune / ConfigMgr / co-managed)
  - `EnrollmentStatus` — MDE enrollment state
  - `HideExclusionsFromLocalAdmins` — whether local admins can see exclusions
  - `DisableLocalAdminMerge` — whether local admin policy merge is disabled
  - `TPExclusions` — whether Tamper Protection covers exclusions
- Displays a management status summary explaining whether exclusion tamper protection is in effect

---

### Updates
- View current local signature versions (AV, AS, NIS) and signature age
- Fetch **latest Microsoft engine, platform, and signature versions** from the Microsoft WDSI website
- Trigger an **Intel signature update** via `MpCmdRun.exe -SignatureUpdate`

---

### Logs
All log viewers include text filtering, level filtering, and a message detail pane.

| Log | Source |
|---|---|
| SENSE Logs | `Microsoft-Windows-SENSE/Operational` |
| Defender AV Logs | `Microsoft-Windows-Windows Defender/Operational` (last 50 events) |
| ASR Block Events | Event IDs 1121, 1122, 5007 |
| Controlled Folder Access | Event IDs 1123, 1124, 5007 |
| Exploit Guard Events | Security-Mitigations and Win32k events |

---

### Performance
- **Run Performance Analyzer** — launches `New-MpPerformanceRecording` in a new PowerShell window
- **Show Performance Report** — opens a recently recorded `.etl` file or browse for a custom one via `Get-MpPerformanceReport`
  - Configurable report windows: `-Overview`, `-TopFiles`, `-TopPaths`, `-TopExtensions`, `-TopProcesses`, `-TopScans`
  - Detail level (nested sub-tables): `-TopScansPerFile`, `-TopProcessesPerFile`, `-TopFilesPerPath`, `-TopScansPerProcess`, `-TopScansPerExtension`
  - Each selected report opens in its own window simultaneously (STA runspace pattern)
  - Report window titles reflect the exact parameters used (e.g. `Get-MpPerformanceReport -TopFiles 10 -TopScansPerFile 10`)
- **Estimated Impact (MPlog)** — parses the most recent `MPLog-*.log` file from `C:\ProgramData\Microsoft\Windows Defender\Support` and displays `EstimatedImpact` entries sorted by impact value
- **Download Client Analyzer** — downloads the [MDE Client Analyzer](https://aka.ms/mdatpanalyzer) to a folder of your choice

---

### Proxy
Displays the current Defender proxy configuration:
- Proxy URL (`ProxyServer`)
- Proxy PAC URL (`ProxyPacUrl`)

---

### Firewall
- **Profile status** — Enabled state, default inbound/outbound action, and log settings for Domain, Private, and Public profiles
- **Firewall Rules viewer** — searchable and filterable by direction, action, enabled state, and profile; shows name, protocol, ports, and program path
- **Firewall Logs viewer** — parses `C:\Windows\System32\LogFiles\Firewall\pfirewall.log`; filterable by IP, action (ALLOW/DROP), protocol, and direction

---

### Troubleshooting Mode
- Displays Troubleshooting Mode status fields from `Get-MpComputerStatus` (requires a recent Defender version):
  - `TroubleShootingMode`, `TroubleShootingModeSource`, start/end times, expiration, quota
- **Refresh** button to re-query status
- **Disable Tamper Protection** — runs `Set-MpPreference -DisableTamperProtection $true` (requires Troubleshooting Mode to be active if policy-enforced)
- **Performance Tuning** — applies settings to reduce scan overhead:
  ```powershell
  Set-MpPreference -CloudBlockLevel 0 -CloudExtendedTimeout 10 -ScanAvgCPULoadFactor 20 `
                   -DisableScanningNetworkFiles $true -EnableFileHashComputation $false `
                   -PUAProtection 0
  ```
- **Full Protection Disable** — disables all major real-time protection components:
  ```powershell
  Set-MpPreference -DisableRealtimeMonitoring $true
  Set-MpPreference -DisableBehaviorMonitoring $true
  Set-MpPreference -DisableBlockAtFirstSeen $true
  Set-MpPreference -DisableIOAVProtection $true
  Set-MpPreference -EnableNetworkProtection 0
  ```

> All Troubleshooting Mode actions show a confirmation dialog and require Tamper Protection to be disabled first if policy-enforced.

---

### Connectivity
Tests TCP port 443 reachability to key MDE cloud endpoints:

| Endpoint |
|---|
| login.microsoftonline.com |
| winatp-gw-cus.microsoft.com |
| winatp-gw-eus.microsoft.com |
| winatp-gw-neu.microsoft.com |
| winatp-gw-weu.microsoft.com |
| us.vortex-win.data.microsoft.com |
| eu.vortex-win.data.microsoft.com |
| settings-win.data.microsoft.com |
| events.data.microsoft.com |

Results open in a sortable DataGrid showing endpoint, port, reachability, and resolved IP address.

---

## Author

**Thomas Verheyden**
- Blog: [vertho.tech](https://vertho.tech/2023/06/30/tool-mde-troubleshooter-is-born/)
- Twitter/X: [@thomasvrhydn](https://twitter.com/thomasvrhydn)
