#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
WAYPAPER_CONFIG="${WAYPAPER_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/waypaper/config.ini}"
WAYPAPER_STATE="${WAYPAPER_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/waypaper/state.ini}"

waypaper --random --no-post-command "$@"

WALLPAPER=$(
    python - "$WAYPAPER_CONFIG" "$WAYPAPER_STATE" <<'PY'
import configparser
import pathlib
import sys

config_path = pathlib.Path(sys.argv[1]).expanduser()
state_path = pathlib.Path(sys.argv[2]).expanduser()

config = configparser.ConfigParser()
config.read(config_path, encoding="utf-8")

use_xdg_state = config.getboolean("Settings", "use_xdg_state", fallback=False)
source_path = state_path if use_xdg_state else config_path
section = "State" if use_xdg_state else "Settings"

source = configparser.ConfigParser()
source.read(source_path, encoding="utf-8")

for wallpaper in source.get(section, "wallpaper", fallback="", raw=True).splitlines():
    wallpaper = wallpaper.strip()
    if wallpaper:
        print(pathlib.Path(wallpaper).expanduser())
        break
PY
)

if [[ -z "$WALLPAPER" ]]; then
    echo "failed to read the current wallpaper from waypaper config" >&2
    exit 1
fi

bash "$SCRIPT_DIR/sync-overview-wallpaper.sh" "$WALLPAPER"
