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
    chmod 755 "${REPORT_DIR}" 2>/dev/null
    fix_ownership "${REPORT_DIR}"
}

# When the script runs under sudo, anything it creates is owned by root and
# lives under the invoking user's home dir (see REPORT_DIR above) -- leaving
# that user unable to open their own reports afterwards. Hand ownership back
# to them and keep things world-readable wherever we can.
fix_ownership() {
    local target="$1"
    if [[ -n "${SUDO_USER:-}" ]]; then
        chown "${SUDO_USER}:$(id -gn "${SUDO_USER}")" "${target}" 2>/dev/null
    fi
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
    # while also saving it to disk. tee is part of the pipeline so the shell
    # waits for it before continuing -- unlike `tee >(cmd)`, which can return
    # before the substituted command finishes writing (most visible on long
    # steps like eBPF statistics, where the file was still empty by the time
    # capture_step returned and export_html_report ran).
    "${func}" "$@" 2>&1 | tee "${file}"
    sed -i -r 's/\x1b\[[0-9;]*m//g' "${file}"
    chmod 644 "${file}" 2>/dev/null
    fix_ownership "${file}"

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
    mdatp diagnostic real-time-protection-statistics --output json > "${out_file}"
    chmod 644 "${out_file}" 2>/dev/null
    fix_ownership "${out_file}"
    log_ok "Saved raw JSON output to: ${out_file}"
    echo ""
    view_json_filtered "${out_file}"
}

# Interactively view a JSON file: pretty-print, sort by a field (desc), or
# filter rows by a substring. Works whether the JSON root is an array of
# records (RTP statistics) or an object wrapping one, e.g. {"eventSource":[...]}
# (the same shape mdatp uses for its Hot Event Sources report).
# Falls back to a plain pretty-print (or raw cat) when jq isn't available,
# since sort/filter both rely on jq to actually parse the structure.
view_json_filtered() {
    local file="$1"

    if ! command -v jq >/dev/null 2>&1; then
        log_warn "'jq' is not installed; showing raw JSON as-is. Install jq to enable pretty-print/sort/filter."
        if command -v python3 >/dev/null 2>&1; then
            python3 -m json.tool "${file}" 2>/dev/null || cat "${file}"
        else
            cat "${file}"
        fi
        return 0
    fi

    if ! jq empty "${file}" 2>/dev/null; then
        log_warn "Output doesn't look like valid JSON; showing it raw."
        cat "${file}"
        return 0
    fi

    # Find the path to the list of records: the root itself if it's an
    # array, otherwise the first field on the root object whose value is
    # an array. Falls back to "" (no list found -> sort/filter unavailable).
    local records_path
    records_path="$(jq -r '
        if type == "array" then "."
        else
            (to_entries | map(select(.value | type == "array")) | first) as $e
            | if $e then ".\($e.key)" else "" end
        end
    ' "${file}")"

    local available_keys=""
    if [[ -n "${records_path}" ]]; then
        available_keys="$(jq -r "${records_path} | if length > 0 then (.[0] | keys_unsorted | join(\", \")) else \"\" end" "${file}" 2>/dev/null)"
    fi

    echo "  How would you like to view the JSON output?"
    echo "    1) Pretty-printed (default)"
    if [[ -n "${available_keys}" ]]; then
        echo "    2) Sorted by a field, descending  (available fields: ${available_keys})"
        echo "    3) Filtered to rows containing a text value"
    fi
    read -rp "  Select an option [1]: " view_choice
    view_choice="${view_choice:-1}"

    case "${view_choice}" in
        2)
            if [[ -z "${available_keys}" ]]; then
                log_warn "No sortable list of records found in this JSON; showing pretty-printed output instead."
                jq '.' "${file}"
                return 0
            fi
            local field top_n filter_body full_filter
            read -rp "  Sort by which field?: " field
            read -rp "  Limit to top N rows (blank = show all): " top_n
            filter_body='sort_by(try (.[$f] | tonumber) catch (.[$f] // "")) | reverse'
            if [[ "${top_n}" =~ ^[0-9]+$ ]]; then
                filter_body="${filter_body} | .[0:${top_n}]"
            fi
            if [[ "${records_path}" == "." ]]; then
                full_filter="${filter_body}"
            else
                full_filter="${records_path} |= (${filter_body})"
            fi
            jq --arg f "${field}" "${full_filter}" "${file}" 2>/dev/null \
                || { log_warn "Could not sort by '${field}'; showing pretty-printed output instead."; jq '.' "${file}"; }
            ;;
        3)
            if [[ -z "${available_keys}" ]]; then
                log_warn "No filterable list of records found in this JSON; showing pretty-printed output instead."
                jq '.' "${file}"
                return 0
            fi
            local text filter_body full_filter
            read -rp "  Only show rows where any field contains (case-insensitive): " text
            filter_body='map(select(any(.[]; (tostring | test($t; "i")))))'
            if [[ "${records_path}" == "." ]]; then
                full_filter="${filter_body}"
            else
                full_filter="${records_path} |= (${filter_body})"
            fi
            jq --arg t "${text}" "${full_filter}" "${file}" 2>/dev/null \
                || { log_warn "Filter failed; showing pretty-printed output instead."; jq '.' "${file}"; }
            ;;
        *)
            jq '.' "${file}"
            ;;
    esac
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
    chmod 644 "${out_file}" 2>/dev/null
    fix_ownership "${out_file}"
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

# ---------- Disable ALL statistics ----------

disable_all_statistics() {
    require_mdatp || return 1
    echo ""
    log_info "This will disable every statistics-gathering feature that was enabled for troubleshooting:"
    echo "  - Real-time-protection-statistics → disabled"
    echo "  - Log level                       → restored to 'info'"
    echo ""
    echo "  Note: Real-time protection itself will NOT be touched."
    echo ""
    read -rp "Proceed? [y/N]: " confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
        log_warn "Cancelled."
        return 0
    fi

    log_info "Step 1/2: Disabling real-time-protection-statistics..."
    run_maybe_sudo mdatp config real-time-protection-statistics --value disabled
    log_ok "RTP statistics disabled."

    log_info "Step 2/2: Restoring log level to 'info'..."
    require_root && run_maybe_sudo mdatp log level set --level info
    log_ok "Log level restored to info."

    log_ok "All statistics-related features have been disabled."
}

# ---------- Full Protection Disable ----------

full_protection_disable() {
    require_mdatp || return 1
    echo ""
    log_warn "This will FULLY DISABLE Microsoft Defender for Endpoint protection on this device:"
    echo "  - Real-time protection → disabled"
    echo "  - Behavior monitoring  → disabled"
    echo "  - Passive mode         → enabled"
    echo ""
    log_warn "The device will be left effectively unprotected. Only use this for isolated troubleshooting."
    read -rp "Proceed? [y/N]: " confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
        log_warn "Cancelled."
        return 0
    fi

    log_info "Step 1/3: Disabling real-time protection..."
    run_maybe_sudo mdatp config real-time-protection --value disabled

    log_info "Step 2/3: Disabling behavior monitoring..."
    run_maybe_sudo mdatp config behavior-monitoring --value disabled

    log_info "Step 3/3: Enabling passive mode..."
    run_maybe_sudo mdatp config passive-mode --value enabled

    log_ok "Full protection disable complete."
    log_warn "Remember to re-enable protection when you finish troubleshooting."
}

# ---------- Performance Tuning ----------

performance_tuning() {
    require_mdatp || return 1
    echo ""
    log_info "This will apply the following performance-tuning settings:"
    echo "  - Cloud diagnostic level              → normal"
    echo "  - Cloud block level                   → normal"
    echo "  - Cloud automatic sample submission    → none"
    echo "  - Archive scanning                     → disabled"
    echo "  - Filesystem exclusions added for      → cifs, fuse, nfs, nfs4, smb"
    echo "  - File hash computation                → disabled"
    echo ""
    read -rp "Proceed? [y/N]: " confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
        log_warn "Cancelled."
        return 0
    fi

    log_info "Step 1/10: Setting cloud diagnostic level to 'normal'..."
    run_maybe_sudo mdatp config cloud-diagnostic-level --value normal

    log_info "Step 2/10: Setting cloud block level to 'normal'..."
    run_maybe_sudo mdatp config cloud-block-level --value normal

    log_info "Step 3/10: Disabling cloud automatic sample submission..."
    run_maybe_sudo mdatp config cloud-automatic-sample-submission --value none

    log_info "Step 4/10: Disabling archive scanning..."
    run_maybe_sudo mdatp config scan-archives --value disabled

    log_info "Step 5/10: Adding filesystem exclusion for 'cifs'..."
    run_maybe_sudo mdatp exclusion fs-type add --fstype cifs

    log_info "Step 6/10: Adding filesystem exclusion for 'fuse'..."
    run_maybe_sudo mdatp exclusion fs-type add --fstype fuse

    log_info "Step 7/10: Adding filesystem exclusion for 'nfs'..."
    run_maybe_sudo mdatp exclusion fs-type add --fstype nfs

    log_info "Step 8/10: Adding filesystem exclusion for 'nfs4'..."
    run_maybe_sudo mdatp exclusion fs-type add --fstype nfs4

    log_info "Step 9/10: Adding filesystem exclusion for 'smb'..."
    run_maybe_sudo mdatp exclusion fs-type add --fstype smb

    log_info "Step 10/10: Disabling file hash computation..."
    run_maybe_sudo mdatp config file-hash-computation --value disabled

    log_ok "Performance tuning complete."
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

# Returns "" if the root of the JSON is itself the array of records, the
# field name if it's the first array-valued field on a wrapping object (e.g.
# "eventSource" for the Hot Event Sources shape), or the sentinel NONE_MARKER
# if no array of records can be found at all.
NONE_MARKER=$'\x01NONE\x01'
json_records_field() {
    local file="$1"
    jq -r --arg none "${NONE_MARKER}" '
        if type == "array" then ""
        else
            (to_entries | map(select(.value | type == "array")) | first) as $e
            | if $e then $e.key else $none end
        end
    ' "${file}" 2>/dev/null
}

# If the step's captured output is JSON holding a non-empty array of record
# objects, print a sortable HTML <table> for it and return 0. Otherwise print
# nothing and return 1, so the caller falls back to a plain <pre> block.
try_render_json_table() {
    local file="$1"
    command -v jq >/dev/null 2>&1 || return 1
    jq empty "${file}" >/dev/null 2>&1 || return 1

    local field table_html
    field="$(json_records_field "${file}")"
    [[ "${field}" == "${NONE_MARKER}" ]] && return 1

    table_html="$(jq -r --arg field "${field}" '
        (if $field == "" then . else .[$field] end) as $arr
        | if ($arr | type) == "array" and ($arr | length) > 0 then
            ($arr[0] | keys_unsorted) as $keys
            | "<table class=\"sortable\"><thead><tr>"
              + ($keys | map("<th>" + (@html) + "</th>") | join(""))
              + "</tr></thead><tbody>"
              + ($arr | map(
                  . as $row
                  | "<tr>" + (reduce $keys[] as $k (""; . + "<td>" + (($row[$k]? // "") | tostring | @html) + "</td>")) + "</tr>"
                ) | join(""))
              + "</tbody></table>"
          else
            ""
          end
    ' "${file}" 2>/dev/null)"

    [[ -z "${table_html}" ]] && return 1
    echo "${table_html}"
    return 0
}

# Detects mdatp's repeated "===== \n Key: Value \n Key: Value ..." block
# format (used by the RTP top-offenders text output) and renders it as a
# sortable HTML table. Prints nothing and returns 1 if the content doesn't
# match that shape, so the caller falls back to a plain <pre> block.
try_render_block_table() {
    local file="$1"
    grep -q '^=\{5,\}[[:space:]]*$' "${file}" 2>/dev/null || return 1

    awk '
        function htmlesc(s) {
            gsub(/&/, "\\&amp;", s)
            gsub(/</, "\\&lt;", s)
            gsub(/>/, "\\&gt;", s)
            return s
        }
        function closeblock() {
            if (!inblock || nkeys == 0) { return }
            nblocks++
            if (nblocks == 1) {
                nheader = nkeys
                for (k = 1; k <= nkeys; k++) { headerKeys[k] = curkeys[k] }
            }
            for (k = 1; k <= nheader; k++) { rows[nblocks, k] = curvals[headerKeys[k]] }
        }
        BEGIN { nblocks = 0; nkeys = 0; inblock = 0 }
        /^=+[[:space:]]*$/ {
            closeblock()
            nkeys = 0; delete curkeys; delete curvals
            inblock = 1
            next
        }
        inblock && index($0, ": ") > 0 {
            idx = index($0, ": ")
            key = substr($0, 1, idx - 1)
            val = substr($0, idx + 2)
            nkeys++
            curkeys[nkeys] = key
            curvals[key] = val
        }
        END {
            closeblock()
            if (nblocks == 0) { exit 1 }
            print "<table class=\"sortable\"><thead><tr>"
            for (k = 1; k <= nheader; k++) { print "<th>" htmlesc(headerKeys[k]) "</th>" }
            print "</tr></thead><tbody>"
            for (r = 1; r <= nblocks; r++) {
                print "<tr>"
                for (k = 1; k <= nheader; k++) { print "<td>" htmlesc(rows[r, k]) "</td>" }
                print "</tr>"
            }
            print "</tbody></table>"
        }
    ' "${file}"
}

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
  .table-wrap{overflow-x:auto;max-height:520px;}
  table.sortable{width:100%;border-collapse:collapse;font-size:.82rem;}
  table.sortable th,table.sortable td{padding:8px 14px;border-bottom:1px solid var(--border);text-align:left;white-space:nowrap;}
  table.sortable thead th{position:sticky;top:0;background:#eef3fa;color:var(--ink);font-weight:600;cursor:pointer;user-select:none;}
  table.sortable thead th:hover{background:#e2ecf9;}
  table.sortable thead th.sort-asc::after{content:" \25B2";color:var(--accent);}
  table.sortable thead th.sort-desc::after{content:" \25BC";color:var(--accent);}
  table.sortable tbody tr:nth-child(even){background:#fafbfd;}
  table.sortable tbody tr:hover{background:#f0f6ff;}
  .table-hint{margin:0;padding:8px 22px;font-size:.74rem;color:var(--muted);background:#fafbfd;border-top:1px solid var(--border);}
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
            local body_html table_html
            if [[ -s "${file}" ]]; then
                table_html="$(try_render_json_table "${file}")"
                if [[ -z "${table_html}" ]]; then
                    table_html="$(try_render_block_table "${file}")"
                fi
                if [[ -n "${table_html}" ]]; then
                    body_html="<div class=\"table-wrap\">${table_html}</div><p class=\"table-hint\">Click a column header to sort.</p>"
                else
                    body_html="<pre>$(html_escape < "${file}")</pre>"
                fi
            else
                body_html="<pre>(no output captured for this step)</pre>"
            fi
            echo "<section class=\"card\" id=\"step-${i}\">"
            echo "  <details open>"
            echo "    <summary>"
            echo "      <span class=\"title-wrap\"><span class=\"badge step\">Step $((i+1))</span>${label}</span>"
            echo "      <span class=\"meta\">${when}</span>"
            echo "    </summary>"
            echo "    ${body_html}"
            echo "  </details>"
            echo "</section>"
        done

        echo "</main>"
        echo "<footer>Generated by mdatp-perf-troubleshoot.sh &middot; Source: "
        echo "<a href=\"https://learn.microsoft.com/en-us/defender-endpoint/linux-support-perf\" target=\"_blank\">learn.microsoft.com/en-us/defender-endpoint/linux-support-perf</a></footer>"

        cat <<'HTML_SCRIPT'
<script>
document.addEventListener('click', function (e) {
  var th = e.target.closest('table.sortable th');
  if (!th) { return; }
  var table = th.closest('table');
  var headerRow = table.tHead.rows[0];
  var ths = Array.prototype.slice.call(headerRow.cells);
  var colIndex = ths.indexOf(th);
  var newDir = th.classList.contains('sort-asc') ? 'desc' : 'asc';
  ths.forEach(function (t) { t.classList.remove('sort-asc', 'sort-desc'); });
  th.classList.add(newDir === 'asc' ? 'sort-asc' : 'sort-desc');

  var tbody = table.tBodies[0];
  var rows = Array.prototype.slice.call(tbody.rows);
  function cellText(row) {
    return (row.cells[colIndex] ? row.cells[colIndex].textContent : '').trim();
  }
  var allNumeric = rows.every(function (r) {
    var v = cellText(r).replace(/["',]/g, '');
    return v === '' || !isNaN(parseFloat(v));
  });
  rows.sort(function (a, b) {
    var av = cellText(a), bv = cellText(b), cmp;
    if (allNumeric) {
      cmp = (parseFloat(av.replace(/["',]/g, '')) || 0) - (parseFloat(bv.replace(/["',]/g, '')) || 0);
    } else {
      cmp = av.localeCompare(bv, undefined, { numeric: true, sensitivity: 'base' });
    }
    return newDir === 'asc' ? cmp : -cmp;
  });
  rows.forEach(function (r) { tbody.appendChild(r); });
});
</script>
HTML_SCRIPT

        echo "</body></html>"
    } > "${html_file}"

    chmod 644 "${html_file}" 2>/dev/null
    fix_ownership "${html_file}"

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
        echo "  5) Disable ALL statistics features"
        echo "  6) Full Protection Disable (RTP + Behavior Monitoring off, Passive Mode on)"
        echo "  7) Performance Tuning (cloud levels, archive scan, fs-type exclusions, file hashing)"
        echo "  8) Run ALL diagnostic collections now (RTP + Hot Event Sources + eBPF)"
        echo "  9) Export session results to HTML report"
        echo " 10) Open reports folder location"
        echo "  0) Exit"
        echo ""
        read -rp "Select an option: " choice
        case "${choice}" in
            1) menu_rtp_statistics ;;
            2) menu_hot_event_sources ;;
            3) menu_ebpf_statistics ;;
            4) capture_step "Enable All Statistics Features"  "enable-all"  enable_all_statistics;  press_enter ;;
            5) capture_step "Disable All Statistics Features" "disable-all" disable_all_statistics; press_enter ;;
            6) capture_step "Full Protection Disable" "full-protection-disable" full_protection_disable; press_enter ;;
            7) capture_step "Performance Tuning" "performance-tuning" performance_tuning; press_enter ;;
            8) run_all_collections; press_enter ;;
            9) export_html_report; press_enter ;;
            10) ensure_report_dir; log_info "Reports are saved to: ${REPORT_DIR}"; press_enter ;;
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
