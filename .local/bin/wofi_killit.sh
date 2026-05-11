#!/bin/bash
# Author: 4ndr0666
# ===================== // KILLIT.SH //
## Description: Standalone Wofi script to search, select, and kill processes.
##              Optimized for Hyprland/Wayland with Polkit privilege escalation.
## --------------------------------------

# Defensive bash execution (allow grep to fail gracefully without crashing script)
set -euo pipefail

# Function to display error messages
error() {
    notify-send "killit - Error" "$1"
}

# Function to fetch processes matching the pattern
fetch_processes() {
    local pattern="$1"
    # pgrep -a shows full command line. Exclude this script's exact PID ($$).
    # grep returns 1 if no match, so we use || true to prevent set -e from killing the script
    pgrep -a -i -f "$pattern" | grep -v "^$$ " || true
}

# Function to display processes in wofi and allow selection
select_processes_wofi() {
    local processes="$1"
    # Note: --multi-select is primarily a rofi feature, but if your wofi fork 
    # supports it or ignores it, we parse the output to extract just the PIDs.
    echo "$processes" | wofi --dmenu \
        --prompt "Select processes to kill:" \
        --multi-select \
        --height 50 \
        --width 800 \
        | awk '{print $1}' || true
}

# Function to prompt for manual PID entry using wofi
manual_pid_entry_wofi() {
    # GAP MITIGATION: Prevent wofi from hanging by piping an empty string.
    # --allow-unmatched ensures the user's raw text input is returned.
    echo "" | wofi --dmenu \
        --prompt "Enter PIDs to kill (separated by spaces):" \
        --height 50 \
        --width 400 \
        --allow-unmatched \
        | tr ',' ' ' | tr '\n' ' ' || true
}

# Function to confirm killing selected PIDs using wofi
confirm_kill_wofi() {
    local pids="$1"
    local confirmation="Yes, Kill Processes\nNo, Cancel\n--- TARGETS ---\n"
    
    for pid in $pids; do
        if ps -p "$pid" &>/dev/null; then
            proc_name=$(ps -p "$pid" -o comm= | head -n 1)
            confirmation+="PID: $pid - $proc_name\n"
        else
            confirmation+="PID: $pid - [Process not found]\n"
        fi
    done

    # GAP MITIGATION: Provide explicit selectable options for Y/N
    local choice
    choice=$(echo -e "$confirmation" | wofi --dmenu \
        --prompt "Confirm Kill?" \
        --height 250 \
        --width 500)

    if [[ "$choice" == "Yes, Kill Processes" ]]; then
        return 0
    else
        return 1
    fi
}

# Main loop
while true; do
    # Prompt for process pattern using wofi
    pattern=$(echo "" | wofi --dmenu \
        --prompt "Enter process name or pattern:" \
        --height 50 \
        --width 400 \
        --allow-unmatched)

    # Exit if no input or user hit escape
    if [[ -z "$pattern" ]]; then
        exit 0
    fi

    # Fetch matching processes
    pids_with_names=$(fetch_processes "$pattern")

    if [[ -z "$pids_with_names" ]]; then
        error "No processes found matching '$pattern'."
        search_again=$(echo -e "Yes\nNo" | wofi --dmenu \
            --prompt "No matches found. Search again?" \
            --height 50 \
            --width 400)
        if [[ "$search_again" != "Yes" ]]; then
            exit 0
        else
            continue
        fi
    fi

    # Display processes and allow selection
    selected_pids=$(select_processes_wofi "$pids_with_names")

    # Allow manual PID entry
    manual_pids=$(manual_pid_entry_wofi)

    # Combine selected and manual PIDs
    all_pids="$selected_pids $manual_pids"

    # Remove duplicates and ensure only numbers are kept
    all_pids=$(echo "$all_pids" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -u | tr '\n' ' ')

    if [[ -z "$all_pids" || "$all_pids" == " " ]]; then
        error "No valid PIDs selected."
        search_again=$(echo -e "Yes\nNo" | wofi --dmenu \
            --prompt "No valid PIDs. Search again?" \
            --height 50 \
            --width 400)
        if [[ "$search_again" != "Yes" ]]; then
            exit 0
        else
            continue
        fi
    fi

    # Confirm before killing
    if confirm_kill_wofi "$all_pids"; then
        for pid in $all_pids; do
            if ps -p "$pid" &>/dev/null; then
                # GAP MITIGATION: Attempt user-level kill first. 
                # If it fails (Permission denied), escalate to pkexec for a GUI password prompt.
                if kill -9 "$pid" &>/dev/null; then
                    notify-send "killit" "Process $pid killed successfully."
                elif pkexec kill -9 "$pid" &>/dev/null; then
                    notify-send "killit" "Process $pid killed (Root override)."
                else
                    notify-send "killit" "Failed to kill process $pid."
                fi
            else
                notify-send "killit" "PID $pid does not exist. Skipping."
            fi
        done
    else
        notify-send "killit" "Kill operation canceled."
    fi

    # Ask if the user wants to perform another kill operation
    again=$(echo -e "Yes\nNo" | wofi --dmenu \
        --prompt "Do you want to kill more processes?" \
        --height 50 \
        --width 400)
        
    if [[ "$again" != "Yes" ]]; then
        exit 0
    fi
done
