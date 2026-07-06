#!/usr/bin/env bash
#
# mdatp-perf-troubleshoot.sh
#
# Interactive menu wrapping the diagnostic steps described in:
# "Troubleshoot performance issues for Microsoft Defender for Endpoint on Linux"
# https://learn.microsoft.com/en-us/defender-endpoint/linux-support-perf
#
# Covers the three official diagnostic approaches:
#   1) Real-time Protection (RTP) Statistics
#   2) Hot Event Sources (files / executables)
#   3) eBPF Statistics
#
# Plus:
#   - "Enable all statistics" convenience option
#   - "Export to HTML" option that builds a single-page report from
#     every check you ran during the session
#
# Requires: mdatp CLI installed, and root/sudo for log-level and hot-event-source commands.

set -uo pipefail

# ---------- Colors ----------
BOLD="\e[1m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
RESET="\e[0m"

# ---------- Globals ----------
# Resolve the real invoking user's home even when the script is run via sudo,
# so reports never land in /root.
if [[ -n "${SUDO_USER:-}" ]]; then
    _REAL_HOME="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
else
    _REAL_HOME="${HOME}"
fi
REPORT_DIR="${_REAL_HOME}/mdatp_perf_reports"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Session tracking arrays (parallel arrays, index-aligned) used to build the HTML report
SESSION_LABELS=()
SESSION_FILES=()
SESSION_TIMES=()

# ---------- Helpers ----------

log_info()  { echo -e "${CYAN}[INFO]${RESET} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${RESET} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET} $*"; }
log_err()   { echo -e "${RED}[ERROR]${RESET} $*"; }

press_enter() {
    echo ""
    read -rp "Press [Enter] to return to the menu..." _
}

require_mdatp() {
    if ! command -v mdatp >/dev/null 2>&1; then
        log_err "'mdatp' CLI not found in PATH. Is Microsoft Defender for Endpoint installed?"
        return 1
    fi
    return 0
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        log_warn "This action requires root permissions. Re-running with sudo..."
        if ! command -v sudo >/dev/null 2>&1; then
            log_err "sudo not found and you are not root. Aborting this action."
            return 1
        fi
    fi
    return 0
}

ensure_report_dir() {
    mkdir -p "${REPORT_DIR}"
}

# Run a command, optionally with sudo if not root
run_maybe_sudo() {
    if [[ "${EUID}" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Escape text for safe embedding inside an HTML <pre> block
html_escape() {
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

# Run a menu action while capturing its full output (colors stripped) into a
# log file and registering it for inclusion in the HTML export.
#   capture_step "Display label" "file-prefix" function_name [args...]
capture_step() {
    local label="$1" fname="$2" func="$3"
    shift 3
    ensure_report_dir
    local file="${REPORT_DIR}/${fname}-${TIMESTAMP}-$$-${RANDOM}.log"

    # Run the real function; tee shows live colored output on the terminal
    # while a process substitution strips ANSI codes for the saved file.
    "${func}" "$@" 2>&1 | tee >(sed -u -r 's/\x1b\[[0-9;]*m//g' > "${file}")

    SESSION_LABELS+=("${label}")
    SESSION_FILES+=("${file}")
    SESSION_TIMES+=("$(date '+%Y-%m-%d %H:%M:%S')")
}

# ---------- Pre-flight ----------

check_other_security_products_notice() {
    log_warn "Before troubleshooting, make sure no OTHER security products are running on this device."
    log_warn "Multiple security products may conflict and impact host performance."
}

# ---------- 1. Real-time Protection Statistics ----------

rtp_disable_and_test() {
    require_mdatp || return 1
    log_info "Disabling real-time protection to test whether performance improves..."
    run_maybe_sudo mdatp config real-time-protection --value disabled
    log_ok "Real-time protection disabled. Now observe system performance."
    log_info "If the issue persists with RTP off, the EDR component may be the cause;"
    log_info "use the 'Hot Event Sources' menu options instead."
}

rtp_enable() {
    require_mdatp || return 1
    log_info "Enabling real-time protection..."
    run_maybe_sudo mdatp config real-time-protection --value enabled
    log_ok "Real-time protection enabled."
}

rtp_enable_statistics() {
    require_mdatp || return 1
    log_info "Checking real_time_protection_enabled health field..."
    local rtp_status
    rtp_status="$(mdatp health --field real_time_protection_enabled 2>/dev/null)"
    echo "  real_time_protection_enabled: ${rtp_status}"

    if [[ "${rtp_status}" != "true" ]]; then
        log_warn "Real-time protection is not enabled. Enabling it now (required for RTP statistics)..."
        run_maybe_sudo mdatp config real-time-protection --value enabled
    fi

    log_info "Enabling real-time-protection-statistics feature..."
    run_maybe_sudo mdatp config real-time-protection-statistics --value enabled
    log_ok "RTP statistics feature enabled. (Note: available in mdatp 100.90.70+; on by default on Dogfood/InsiderFast)."
}

rtp_collect_statistics() {
    require_mdatp || return 1
    ensure_report_dir
    local out_file="${REPORT_DIR}/rtp-statistics-raw-${TIMESTAMP}.json"
    log_info "Collecting current RTP statistics (JSON output)..."
    mdatp diagnostic real-time-protection-statistics --output json | tee "${out_file}"
    log_ok "Saved raw JSON output to: ${out_file}"
}

rtp_top_offenders() {
    require_mdatp || return 1
    local top_n
    read -rp "How many top contributors to show? [default: 4]: " top_n
    top_n="${top_n:-4}"
    log_info "Fetching top ${top_n} processes by scan activity..."
    mdatp diagnostic real-time-protection-statistics --sort --top "${top_n}"
    echo ""
    log_info "Look for the process with the highest 'Total files scanned' value."
    log_info "Consider adding an antivirus exclusion for it after careful evaluation."
}

menu_rtp_statistics() {
    while true; do
        echo ""
        echo -e "${BOLD}== Real-time Protection (RTP) Statistics ==${RESET}"
        echo "  Applies to: antivirus-related performance issues"
        echo ""
        echo "  1) Disable real-time protection and test performance"
        echo "  2) Re-enable real-time protection"
        echo "  3) Enable RTP statistics feature (checks/enables RTP first)"
        echo "  4) Collect current RTP statistics (JSON, saved to file)"
        echo "  5) Show top N processes triggering the most scans"
        echo "  0) Back to main menu"
        echo ""
        read -rp "Select an option: " choice
        case "${choice}" in
            1) capture_step "RTP: Disable & Test"          "rtp-disable"      rtp_disable_and_test; press_enter ;;
            2) capture_step "RTP: Re-enable"                "rtp-enable"       rtp_enable; press_enter ;;
            3) capture_step "RTP: Enable Statistics"        "rtp-enable-stats" rtp_enable_statistics; press_enter ;;
            4) capture_step "RTP: Collect Statistics"       "rtp-collect"      rtp_collect_statistics; press_enter ;;
            5) capture_step "RTP: Top Offending Processes"  "rtp-top"          rtp_top_offenders; press_enter ;;
            0) break ;;
            *) log_warn "Invalid option." ;;
        esac
    done
}

# ---------- 2. Hot Event Sources ----------

hes_check_log_level() {
    require_mdatp || return 1
    log_info "Checking current mdatp log level..."
    local level
    level="$(mdatp health --field log_level 2>/dev/null)"
    echo "  log_level: ${level}"
    if [[ "${level}" != "debug" ]]; then
        log_warn "Log level is not 'debug'. Hot Event Sources requires debug logging for detailed reports."
    else
        log_ok "Log level is already set to 'debug'."
    fi
}

hes_set_debug() {
    require_root || return 1
    log_info "Setting log level to 'debug'..."
    run_maybe_sudo mdatp log level set --level debug
    log_ok "Log level set to debug."
}

hes_set_info() {
    require_root || return 1
    log_info "Restoring log level to 'info'..."
    run_maybe_sudo mdatp log level set --level info
    log_ok "Log level set back to info."
}

hes_collect_files() {
    require_mdatp || return 1
    require_root || return 1
    ensure_report_dir
    log_info "Collecting Hot Event Sources for FILES (requires root; runs until you stop it or it completes)..."
    log_warn "Ensure log level is 'debug' first (menu option 1) for a detailed report."
    run_maybe_sudo mdatp diagnostic hot-event-sources files
    log_ok "Command finished. A hot event source JSON report should be saved in the local folder mdatp writes to."
    log_info "Look at the file with the highest 'count' to identify the noisiest file."
}

hes_collect_executables() {
    require_mdatp || return 1
    require_root || return 1
    ensure_report_dir
    log_info "Collecting Hot Event Sources for EXECUTABLES (requires root)..."
    log_warn "Ensure log level is 'debug' first (menu option 1) for a detailed report."
    run_maybe_sudo mdatp diagnostic hot-event-sources executables
    log_ok "Command finished. A hot event source JSON report should be saved in the local folder mdatp writes to."
    log_info "Look at the executable with the highest 'count' to identify the noisiest process."
}

menu_hot_event_sources() {
    while true; do
        echo ""
        echo -e "${BOLD}== Hot Event Sources ==${RESET}"
        echo "  Applies to: files/executables consuming the most CPU cycles filesystem-wide"
        echo "  Note: requires root/sudo."
        echo ""
        echo "  1) Check current log level"
        echo "  2) Set log level to 'debug' (required before collecting)"
        echo "  3) Collect Hot Event Sources - FILES"
        echo "  4) Collect Hot Event Sources - EXECUTABLES"
        echo "  5) Restore log level to 'info' (after investigation)"
        echo "  0) Back to main menu"
        echo ""
        read -rp "Select an option: " choice
        case "${choice}" in
            1) capture_step "Hot Event Sources: Check Log Level"    "hes-loglevel"   hes_check_log_level; press_enter ;;
            2) capture_step "Hot Event Sources: Set Debug Logging"  "hes-setdebug"   hes_set_debug; press_enter ;;
            3) capture_step "Hot Event Sources: Files"              "hes-files"      hes_collect_files; press_enter ;;
            4) capture_step "Hot Event Sources: Executables"        "hes-execs"      hes_collect_executables; press_enter ;;
            5) capture_step "Hot Event Sources: Restore Info Logging" "hes-setinfo" hes_set_info; press_enter ;;
            0) break ;;
            *) log_warn "Invalid option." ;;
        esac
    done
}

# ---------- 3. eBPF Statistics ----------

ebpf_collect_statistics() {
    require_mdatp || return 1
    ensure_report_dir
    local out_file="${REPORT_DIR}/ebpf-statistics-raw-${TIMESTAMP}.txt"
    log_info "Collecting eBPF statistics. This monitors the system for ~20 seconds..."
    mdatp diagnostic ebpf-statistics | tee "${out_file}"
    log_ok "Saved output to: ${out_file}"
    log_info "Check 'Top initiator paths' for the process generating the most syscalls,"
    log_info "and 'Top syscall ids' for which syscalls dominate."
}

menu_ebpf_statistics() {
    while true; do
        echo ""
        echo -e "${BOLD}== eBPF Statistics ==${RESET}"
        echo "  Applies to: all file/process events, including syscall-based performance issues"
        echo ""
        echo "  1) Collect eBPF statistics (~20 second capture)"
        echo "  0) Back to main menu"
        echo ""
        read -rp "Select an option: " choice
        case "${choice}" in
            1) capture_step "eBPF Statistics" "ebpf-collect" ebpf_collect_statistics; press_enter ;;
            0) break ;;
            *) log_warn "Invalid option." ;;
        esac
    done
}

# ---------- Enable ALL statistics ----------

enable_all_statistics() {
    require_mdatp || return 1
    echo ""
    log_info "This will enable every statistics-gathering feature described in the guide:"
    echo "  - Real-time protection (enabled if not already)"
    echo "  - Real-time-protection-statistics"
    echo "  - Log level set to 'debug' (needed for Hot Event Sources)"
    echo ""
    read -rp "Proceed? [y/N]: " confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
        log_warn "Cancelled."
        return 0
    fi

    log_info "Step 1/3: Ensuring real-time protection is enabled..."
    run_maybe_sudo mdatp config real-time-protection --value enabled

    log_info "Step 2/3: Enabling real-time-protection-statistics..."
    run_maybe_sudo mdatp config real-time-protection-statistics --value enabled

    log_info "Step 3/3: Setting log level to 'debug' for Hot Event Sources detail..."
    require_root && run_maybe_sudo mdatp log level set --level debug

    log_ok "All statistics-related features are now enabled."
    log_warn "Remember: eBPF statistics don't require an 'enable' step, just run the collection command."
    log_warn "Remember to set log level back to 'info' when you finish your investigation (menu 2 > option 5)."
}

# ---------- Diagnostics summary / run-all collection ----------

run_all_collections() {
    require_mdatp || return 1
    ensure_report_dir
    log_warn "This will run RTP stats, Hot Event Sources (files + executables), and eBPF stats back-to-back."
    log_warn "Hot Event Sources requires root and debug logging; eBPF capture takes ~20s."
    read -rp "Proceed? [y/N]: " confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
        log_warn "Cancelled."
        return 0
    fi

    echo ""
    log_info ">>> Real-time Protection Statistics <<<"
    capture_step "RTP: Collect Statistics"      "rtp-collect"    rtp_collect_statistics
    capture_step "RTP: Top Offending Processes" "rtp-top"        rtp_top_offenders

    echo ""
    log_info ">>> Hot Event Sources: Files <<<"
    capture_step "Hot Event Sources: Check Log Level" "hes-loglevel" hes_check_log_level
    capture_step "Hot Event Sources: Files"           "hes-files"    hes_collect_files

    echo ""
    log_info ">>> Hot Event Sources: Executables <<<"
    capture_step "Hot Event Sources: Executables" "hes-execs" hes_collect_executables

    echo ""
    log_info ">>> eBPF Statistics <<<"
    capture_step "eBPF Statistics" "ebpf-collect" ebpf_collect_statistics

    log_ok "All collections complete. Reports saved under: ${REPORT_DIR}"
}

# ---------- HTML Export ----------

export_html_report() {
    if [[ "${#SESSION_LABELS[@]}" -eq 0 ]]; then
        log_warn "No checks have been run yet in this session."
        log_warn "Run some diagnostics from the menus first, then come back and export."
        return 0
    fi

    ensure_report_dir
    local html_file="${REPORT_DIR}/mdatp-perf-report-${TIMESTAMP}.html"
    log_info "Building HTML report from ${#SESSION_LABELS[@]} recorded check(s)..."

    {
        cat <<'HTML_HEAD'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MDE Linux Performance Troubleshooting Report</title>
<style>
  :root{
    --bg:#f4f6fb; --card:#ffffff; --ink:#1b1f27; --muted:#5b6270;
    --accent:#0f6cbd; --ok:#1e8e3e; --warn:#c77700; --border:#e2e5eb;
  }
  *{box-sizing:border-box;}
  body{margin:0;font-family:-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;background:var(--bg);color:var(--ink);}
  header{background:linear-gradient(135deg,#0f6cbd,#123f73);color:#fff;padding:36px 44px;}
  header h1{margin:0 0 8px;font-size:1.55rem;}
  header p{margin:2px 0;opacity:.85;font-size:.88rem;}
  main{max-width:980px;margin:0 auto;padding:28px 20px 60px;}
  .summary-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:14px;margin-bottom:26px;}
  .stat{background:var(--card);border:1px solid var(--border);border-radius:10px;padding:16px 18px;}
  .stat .num{font-size:1.6rem;font-weight:700;color:var(--accent);}
  .stat .label{font-size:.78rem;color:var(--muted);text-transform:uppercase;letter-spacing:.04em;}
  nav.toc{background:var(--card);border:1px solid var(--border);border-radius:10px;padding:18px 22px;margin-bottom:26px;}
  nav.toc h2{margin:0 0 10px;font-size:.85rem;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;}
  nav.toc ol{margin:0;padding-left:20px;}
  nav.toc li{margin:4px 0;font-size:.92rem;}
  nav.toc a{color:var(--accent);text-decoration:none;}
  nav.toc a:hover{text-decoration:underline;}
  section.card{background:var(--card);border:1px solid var(--border);border-radius:10px;margin-bottom:18px;overflow:hidden;}
  section.card summary{cursor:pointer;padding:16px 22px;font-weight:600;display:flex;align-items:center;justify-content:space-between;gap:14px;list-style:none;}
  section.card summary::-webkit-details-marker{display:none;}
  section.card summary::before{content:"▸";display:inline-block;margin-right:10px;color:var(--accent);transition:transform .15s ease;}
  section.card details[open] summary::before{transform:rotate(90deg);}
  summary .title-wrap{display:flex;align-items:center;}
  summary .meta{font-weight:400;font-size:.78rem;color:var(--muted);white-space:nowrap;}
  section.card pre{margin:0;padding:18px 22px;background:#0d1117;color:#d7dce1;overflow-x:auto;font-size:.8rem;line-height:1.55;max-height:520px;white-space:pre-wrap;word-break:break-word;}
  .badge{display:inline-block;padding:2px 11px;border-radius:20px;font-size:.72rem;font-weight:600;margin-right:12px;}
  .badge.step{background:#e8f0fb;color:var(--accent);}
  footer{text-align:center;color:var(--muted);font-size:.78rem;padding:24px 20px;}
  footer a{color:var(--accent);text-decoration:none;}
</style>
</head>
<body>
HTML_HEAD

        echo "<header>"
        echo "  <h1>Microsoft Defender for Endpoint on Linux &mdash; Performance Report</h1>"
        echo "  <p>Generated $(date '+%Y-%m-%d %H:%M:%S %Z') on host <strong>$(hostname)</strong></p>"
        echo "  <p>Based on: <em>Troubleshoot performance issues for Microsoft Defender for Endpoint on Linux</em> (Microsoft Learn)</p>"
        echo "</header>"
        echo "<main>"

        echo "<div class=\"summary-grid\">"
        echo "  <div class=\"stat\"><div class=\"num\">${#SESSION_LABELS[@]}</div><div class=\"label\">Checks run</div></div>"
        echo "  <div class=\"stat\"><div class=\"num\">$(hostname)</div><div class=\"label\">Host</div></div>"
        echo "  <div class=\"stat\"><div class=\"num\">$(date '+%H:%M:%S')</div><div class=\"label\">Report time</div></div>"
        echo "</div>"

        echo "<nav class=\"toc\"><h2>Checks included in this report</h2><ol>"
        local i
        for i in "${!SESSION_LABELS[@]}"; do
            echo "  <li><a href=\"#step-${i}\">${SESSION_LABELS[$i]}</a></li>"
        done
        echo "</ol></nav>"

        for i in "${!SESSION_LABELS[@]}"; do
            local label="${SESSION_LABELS[$i]}"
            local file="${SESSION_FILES[$i]}"
            local when="${SESSION_TIMES[$i]}"
            local content
            if [[ -s "${file}" ]]; then
                content="$(html_escape < "${file}")"
            else
                content="(no output captured for this step)"
            fi
            echo "<section class=\"card\" id=\"step-${i}\">"
            echo "  <details open>"
            echo "    <summary>"
            echo "      <span class=\"title-wrap\"><span class=\"badge step\">Step $((i+1))</span>${label}</span>"
            echo "      <span class=\"meta\">${when}</span>"
            echo "    </summary>"
            echo "    <pre>${content}</pre>"
            echo "  </details>"
            echo "</section>"
        done

        echo "</main>"
        echo "<footer>Generated by mdatp-perf-troubleshoot.sh &middot; Source: "
        echo "<a href=\"https://learn.microsoft.com/en-us/defender-endpoint/linux-support-perf\" target=\"_blank\">learn.microsoft.com/en-us/defender-endpoint/linux-support-perf</a></footer>"
        echo "</body></html>"
    } > "${html_file}"

    log_ok "HTML report saved to: ${html_file}"
    log_info "Open it with, e.g.: xdg-open \"${html_file}\"  (or copy it to a machine with a GUI/browser)."
}

# ---------- Main menu ----------

main_menu() {
    while true; do
        clear
        echo -e "${BOLD}=====================================================${RESET}"
        echo -e "${BOLD} Microsoft Defender for Endpoint on Linux${RESET}"
        echo -e "${BOLD} Performance Troubleshooting Toolkit${RESET}"
        echo -e "${BOLD}=====================================================${RESET}"
        check_other_security_products_notice
        echo ""
        echo "  Checks recorded so far this session: ${#SESSION_LABELS[@]}"
        echo ""
        echo "  1) Real-time Protection (RTP) Statistics menu"
        echo "  2) Hot Event Sources menu"
        echo "  3) eBPF Statistics menu"
        echo "  4) Enable ALL statistics features"
        echo "  5) Run ALL diagnostic collections now (RTP + Hot Event Sources + eBPF)"
        echo "  6) Export session results to HTML report"
        echo "  7) Open reports folder location"
        echo "  0) Exit"
        echo ""
        read -rp "Select an option: " choice
        case "${choice}" in
            1) menu_rtp_statistics ;;
            2) menu_hot_event_sources ;;
            3) menu_ebpf_statistics ;;
            4) capture_step "Enable All Statistics Features" "enable-all" enable_all_statistics; press_enter ;;
            5) run_all_collections; press_enter ;;
            6) export_html_report; press_enter ;;
            7) ensure_report_dir; log_info "Reports are saved to: ${REPORT_DIR}"; press_enter ;;
            0)
                if [[ "${#SESSION_LABELS[@]}" -gt 0 ]]; then
                    read -rp "Export HTML report before exiting? [y/N]: " export_confirm
                    if [[ "${export_confirm}" =~ ^[Yy]$ ]]; then
                        export_html_report
                    fi
                fi
                echo "Goodbye."
                exit 0
                ;;
            *) log_warn "Invalid option."; sleep 1 ;;
        esac
    done
}

main_menu
