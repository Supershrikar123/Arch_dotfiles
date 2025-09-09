#!/bin/bash

WAYBAR_CMD="waybar"
WORKSPACE=3
LOG_FILE="/tmp/waybar-manager.log"

log() {
    echo "$(date '+%F %T') - $1" >> "$LOG_FILE"
}

while true; do
    # Check if Waybar is running
    pgrep -x waybar > /dev/null
    WAYBAR_RUNNING=$?

    # Reset counters
    NATIVE_PROTON_COUNT=0
    OTHER_COUNT=0

    # Get all clients as JSON lines
    mapfile -t clients < <(hyprctl clients -j | jq -c '.[]')

    for client in "${clients[@]}"; do
        title=$(echo "$client" | jq -r '.title')
        class=$(echo "$client" | jq -r '.class')
        address=$(echo "$client" | jq -r '.address')

        if [[ "$title" == "$class" ]]; then
            ((NATIVE_PROTON_COUNT++))
        elif [[ "$class" =~ ^steam_app_ ]]; then
            ((NATIVE_PROTON_COUNT++))
            # Move Steam/Proton window to workspace 3
            if [[ -n "$address" ]]; then
                hyprctl dispatch movetoworkspace $WORKSPACE window:$address
                log "Moved $title ($class) to workspace $WORKSPACE"
            else
                log "No address for $title ($class), cannot move"
            fi
        else
            ((OTHER_COUNT++))
        fi
    done

    # Waybar logic
    if [[ "$NATIVE_PROTON_COUNT" -gt 0 ]]; then
        if [[ "$WAYBAR_RUNNING" -eq 0 ]]; then
            log "Native/Proton game detected. Killing Waybar."
            pkill -x waybar
        fi
    elif [[ "$OTHER_COUNT" -gt 0 ]]; then
        if [[ "$WAYBAR_RUNNING" -ne 0 ]]; then
            log "Other windows open. Starting Waybar."
            $WAYBAR_CMD &
        fi
    else
        if [[ "$WAYBAR_RUNNING" -eq 0 ]]; then
            log "No windows open. Killing Waybar."
            pkill -x waybar
        fi
    fi

    sleep 1
done
