#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "usage: sync-overview-wallpaper.sh <wallpaper>" >&2
    exit 1
fi

WALLPAPER=$1
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/swww"
OVERVIEW_WALLPAPER="$CACHE_DIR/overview.png"
OVERVIEW_INSTANCE="overview"
OVERVIEW_BLUR="${OVERVIEW_BLUR:-0x20}"
OVERVIEW_DIM="${OVERVIEW_DIM:-0.6}"

mkdir -p "$CACHE_DIR"

ensure_overview_daemon() {
    if swww query -n "$OVERVIEW_INSTANCE" >/dev/null 2>&1; then
        return
    fi

    nohup swww-daemon -n "$OVERVIEW_INSTANCE" >/dev/null 2>&1 &

    for _ in $(seq 1 20); do
        if swww query -n "$OVERVIEW_INSTANCE" >/dev/null 2>&1; then
            return
        fi

        sleep 0.2
    done

    echo "overview swww-daemon is not ready" >&2
    exit 1
}

magick "$WALLPAPER" \
    -blur "$OVERVIEW_BLUR" \
    -evaluate multiply "$OVERVIEW_DIM" \
    "$OVERVIEW_WALLPAPER"

ensure_overview_daemon

for _ in $(seq 1 5); do
    if swww img "$OVERVIEW_WALLPAPER" -n "$OVERVIEW_INSTANCE" --transition-type none >/dev/null 2>&1; then
        exit 0
    fi

    sleep 0.2
done

echo "failed to update overview wallpaper" >&2
exit 1
