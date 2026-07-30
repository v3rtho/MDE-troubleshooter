# mdatp-perf-troubleshoot.sh

An interactive bash menu for troubleshooting **Microsoft Defender for Endpoint (MDE) performance issues on Linux**, wrapping the diagnostic steps from the [official Microsoft Learn guide](https://learn.microsoft.com/en-us/defender-endpoint/linux-support-perf).

Every action you run is captured into a log file and can be exported as a single self-contained **HTML report** at the end of your session.

---

## Requirements

- Linux (any distribution supported by MDE)
- `mdatp` CLI installed and working
- `bash` 4.0+
- `sudo` or root access (required for log-level and Hot Event Sources commands)

---

## Quick Start

```bash
# Make it executable
chmod +x mdatp-perf-troubleshoot.sh

# Run (use sudo if you need Hot Event Sources or log-level commands)
sudo ./mdatp-perf-troubleshoot.sh
```

> **Note:** When run with `sudo`, reports are always saved to the **invoking user's** home directory — never to `/root`.

---

## Features

### 1 — Real-time Protection (RTP) Statistics
Covers antivirus-related performance issues.

| Option | Description |
|--------|-------------|
| Disable RTP & test | Temporarily disables real-time protection to confirm it is the source of the slowdown |
| Re-enable RTP | Restores real-time protection |
| Enable RTP statistics | Ensures RTP is on and enables the statistics feature (`mdatp 100.90.70+`) |
| Collect RTP statistics | Dumps current scan statistics to a JSON file |
| Show top N processes | Displays the processes generating the most scan activity |

### 2 — Hot Event Sources
Identifies the noisiest files or executables at the filesystem level. Requires root and debug logging.

| Option | Description |
|--------|-------------|
| Check log level | Shows the current `mdatp` log level |
| Set log level to `debug` | Required before collecting Hot Event Sources for detailed output |
| Collect — Files | Runs `mdatp diagnostic hot-event-sources files` |
| Collect — Executables | Runs `mdatp diagnostic hot-event-sources executables` |
| Restore log level to `info` | Cleans up after investigation |

### 3 — eBPF Statistics
Captures syscall-level activity across all file and process events (~20 second capture).

### 4 / 5 — Enable / Disable ALL Statistics
Convenience shortcuts that toggle every statistics-gathering feature in one step:

| Feature | Enable (4) | Disable (5) |
|---------|------------|-------------|
| Real-time protection | Ensured on | Left untouched |
| RTP statistics | `enabled` | `disabled` |
| Log level | Set to `debug` | Restored to `info` |

### 6 — Run ALL Collections
Runs RTP statistics, Hot Event Sources (files + executables), and eBPF statistics back-to-back in a single pass.

### 7 — Export to HTML
Builds a self-contained HTML report from every check run during the current session — including command output, timestamps, and a clickable table of contents. Ready to share or attach to a support ticket.

---

## Report Output

All output files and the HTML report are saved to:

```
~/mdatp_perf_reports/
```

| File | Contents |
|------|----------|
| `rtp-statistics-raw-<timestamp>.json` | Raw JSON from `mdatp diagnostic real-time-protection-statistics` |
| `ebpf-statistics-raw-<timestamp>.txt` | Raw text from `mdatp diagnostic ebpf-statistics` |
| `<step>-<timestamp>.log` | Captured terminal output for each menu action |
| `mdatp-perf-report-<timestamp>.html` | Full session report, ready to open in any browser |

---

## Diagnostic Approach

The script follows the three-track approach from the Microsoft documentation:

```
Performance issue on Linux
        │
        ├─ Antivirus-related?      →  RTP Statistics      (menu 1)
        │
        ├─ Specific file / process noisy?  →  Hot Event Sources  (menu 2)
        │
        └─ Syscall / EDR-related?  →  eBPF Statistics     (menu 3)
```

> If disabling real-time protection (menu 1 → option 1) does **not** improve performance, the EDR component is likely the cause — proceed to Hot Event Sources or eBPF statistics.

---

## Permissions

| Action | Requires root? |
|--------|---------------|
| Read health fields | No |
| Enable / disable RTP | Yes (sudo) |
| Enable RTP statistics | Yes (sudo) |
| Set log level | Yes (sudo) |
| Hot Event Sources | Yes (sudo) |
| Collect eBPF statistics | No |
| Export HTML report | No |

---

## References

- [Troubleshoot performance issues for MDE on Linux — Microsoft Learn](https://learn.microsoft.com/en-us/defender-endpoint/linux-support-perf)
- [Microsoft Defender for Endpoint on Linux — Microsoft Docs](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint-linux)
