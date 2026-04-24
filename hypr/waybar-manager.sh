#!/bin/bash
WAYBAR_CMD="waybar"
LOG_FILE="/tmp/waybar-manager.log"
GAME_WINDOWS=("steam_app_")

declare -A MOVE_TARGETS=(
    ["discord"]=4
    ["spotify"]=4
    ["minecraft launcher"]=3
)

declare -A moved_windows
shopt -s nocasematch

log() {
    echo "$(date '+%F %T') - $1" >> "$LOG_FILE"
}

while true; do
    if pgrep -x waybar > /dev/null; then
        WAYBAR_RUNNING=0
    else
        WAYBAR_RUNNING=1
    fi

    GAME_COUNT=0
    OTHER_COUNT=0

    # ✅ Check focused window
    ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')
    ACTIVE_CLASS_LOWER="${ACTIVE_CLASS,,}"

    GAME_FOCUSED=0
    for target in "${GAME_WINDOWS[@]}"; do
        if [[ "$ACTIVE_CLASS_LOWER" == *"${target,,}"* ]]; then
            GAME_FOCUSED=1
            break
        fi
    done

    mapfile -t clients < <(hyprctl clients -j | jq -c '.[]')

    for client in "${clients[@]}"; do
        title=$(echo "$client" | jq -r '.title')
        class=$(echo "$client" | jq -r '.class')
        address=$(echo "$client" | jq -r '.address')
        workspace_id=$(echo "$client" | jq -r '.workspace.id')

        class_lower="${class,,}"

        is_game=0
        target_workspace=""

        for target in "${GAME_WINDOWS[@]}"; do
            if [[ "$class_lower" == *"${target,,}"* ]]; then
                is_game=1
                break
            fi
        done

        for app in "${!MOVE_TARGETS[@]}"; do
            if [[ "$class_lower" == *"${app,,}"* ]]; then
                target_workspace="${MOVE_TARGETS[$app]}"
                break
            fi
        done

        log "DEBUG: title='$title' class='$class' ws=$workspace_id target='$target_workspace' moved='${moved_windows[$address]}'"

        # ✅ Skip unassigned workspaces (-1), retry next loop if needed
        if [[ -n "$target_workspace" && -n "$address" ]] && (( workspace_id != target_workspace )) && (( workspace_id != -1 )); then
            if [[ -z "${moved_windows[$address]}" ]]; then
                sleep 0.5
                hyprctl dispatch movetoworkspace "$target_workspace,address:$address"
                moved_windows[$address]=1
                log "Moved '$title' ($class) to workspace $target_workspace"
            fi
        fi

        if [[ $is_game -eq 1 ]]; then
            ((GAME_COUNT++))
        else
            ((OTHER_COUNT++))
        fi
    done

    # ✅ Waybar logic: focus-aware
    if [[ "$GAME_FOCUSED" -eq 1 ]] || [[ "$OTHER_COUNT" -eq 0 && "$GAME_COUNT" -eq 0 ]]; then
        if [[ "$WAYBAR_RUNNING" -eq 0 ]]; then
            log "Game focused or no windows. Killing Waybar."
            pkill -x waybar
        fi
    else
        if [[ "$WAYBAR_RUNNING" -ne 0 ]]; then
            log "Non-game focused. Starting Waybar."
            $WAYBAR_CMD &
        fi
    fi

    sleep 1
done