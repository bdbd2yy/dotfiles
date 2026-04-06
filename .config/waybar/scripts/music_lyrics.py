#!/usr/bin/env python3

from __future__ import annotations

import argparse
import bisect
import math
import json
import os
import re
import subprocess
import sys
import unicodedata
from dataclasses import dataclass


LRC_TIMESTAMP_RE = re.compile(r"\[(\d+):(\d+(?:\.\d+)?)\]")
MUSICFOX_PLAYER = "musicfox"
MPD_PLAYER = "mpd"
STATUS_RANK = {"Playing": 0, "Paused": 1, "Stopped": 2}
LATIN_LETTER_RE = re.compile(r"[A-Za-z]")
CJK_RE = re.compile(
    r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af]"
)
BRACKETED_TRANSLATION_RE = re.compile(
    r"\s*[\[【](?=[^\]】]*[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af])[^\]】]*[\]】]"
)
CREDIT_PREFIX_RE = re.compile(
    r"^(作词|作曲|编曲|制作人|混音|母带|监制|出品人|版权|音乐企划|统筹|和声|鼓|贝斯|钢琴|箱琴|笛子|弦乐|人声编辑|联合出品|宣发团队|特别企划|制作&宣发公司|Lyricist|Composer|Arranger|Producer|Mix(?:ed)?|Master(?:ed)?|Vocals?|Backing Vocals?|Guitar|Bass|Drums|Piano|Strings?)\s*[:：]",
    re.IGNORECASE,
)
STATE_DIR = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"), "waybar-music"
)
LAST_PLAYER_FILE = os.path.join(STATE_DIR, "last-player")


@dataclass(frozen=True)
class LyricLine:
    timestamp: float
    text: str


@dataclass(frozen=True)
class PlayerState:
    name: str
    status: str


def run_command(command: list[str]) -> str | None:
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def list_players() -> list[str]:
    output = run_command(["playerctl", "-l"])
    if not output:
        return []
    return [line.strip() for line in output.splitlines() if line.strip()]


def has_player(players: list[str], prefix: str) -> bool:
    return any(
        player == prefix or player.startswith(f"{prefix}.") for player in players
    )


def player_family(player: str) -> str:
    return player.split(".", 1)[0]


def player_family_rank(player: str) -> int:
    family = player_family(player)
    if family == MUSICFOX_PLAYER:
        return 0
    if family == MPD_PLAYER:
        return 2
    return 1


def playerctl(*args: str, player: str | None = None) -> str | None:
    command = ["playerctl"]
    if player is not None:
        command.extend(["-p", player])
    command.extend(args)
    return run_command(command)


def get_track_label(player: str | None) -> str:
    title = playerctl("metadata", "title", player=player) or ""
    artist = playerctl("metadata", "artist", player=player) or ""
    if title and artist:
        return f"{title} - {artist}"
    if title:
        return title
    if artist:
        return artist
    return "No music"


def get_player_states(players: list[str]) -> list[PlayerState]:
    states: list[PlayerState] = []
    for player in players:
        status = playerctl("status", player=player)
        if status is None:
            continue
        states.append(PlayerState(name=player, status=status))
    return states


def select_player(states: list[PlayerState]) -> PlayerState | None:
    if not states:
        return None
    return min(
        states,
        key=lambda state: (
            STATUS_RANK.get(state.status, 99),
            player_family_rank(state.name),
            state.name,
        ),
    )


def load_last_active_player() -> str | None:
    try:
        with open(LAST_PLAYER_FILE, encoding="utf-8") as handle:
            player = handle.read().strip()
    except OSError:
        return None
    return player or None


def save_last_active_player(player: str) -> None:
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(LAST_PLAYER_FILE, "w", encoding="utf-8") as handle:
            handle.write(player)
    except OSError:
        return


def resolve_selected_player(states: list[PlayerState]) -> PlayerState | None:
    if not states:
        return None

    playing_states = [state for state in states if state.status == "Playing"]
    if playing_states:
        selected = select_player(playing_states)
        if selected is not None:
            save_last_active_player(selected.name)
        return selected

    last_player = load_last_active_player()
    if last_player is not None:
        for state in states:
            if state.name == last_player:
                return state

    return select_player(states)


def get_position(preferred_player: str | None, has_mpd_player: bool) -> float | None:
    candidates: list[str | None] = []
    if preferred_player is not None:
        candidates.append(preferred_player)
    if has_mpd_player and preferred_player != MPD_PLAYER:
        candidates.append(MPD_PLAYER)

    fallback_position: float | None = None
    for player in candidates:
        output = playerctl("position", player=player)
        if output is None:
            continue
        try:
            position = float(output)
        except ValueError:
            continue
        if position > 0:
            return position
        if fallback_position is None:
            fallback_position = position
    return fallback_position


def parse_lrc(raw_lyrics: str) -> list[LyricLine]:
    entries: list[LyricLine] = []
    for raw_line in raw_lyrics.splitlines():
        timestamps = LRC_TIMESTAMP_RE.findall(raw_line)
        if not timestamps:
            continue

        text = clean_lyric_text(LRC_TIMESTAMP_RE.sub("", raw_line).strip())
        for minutes, seconds in timestamps:
            entries.append(LyricLine(int(minutes) * 60 + float(seconds), text))

    entries.sort(key=lambda item: item.timestamp)
    return entries


def current_lyric(entries: list[LyricLine], position: float) -> LyricLine | None:
    if not entries:
        return None

    timestamps = [entry.timestamp for entry in entries]
    index = bisect.bisect_right(timestamps, position) - 1
    while index >= 0:
        entry = entries[index]
        if entry.text:
            return entry
        index -= 1
    return None


def current_lyric_index(entries: list[LyricLine], position: float) -> int | None:
    if not entries:
        return None

    timestamps = [entry.timestamp for entry in entries]
    index = bisect.bisect_right(timestamps, position) - 1
    while index >= 0:
        if entries[index].text:
            return index
        index -= 1
    return None


def clean_lyric_text(text: str) -> str:
    if not LATIN_LETTER_RE.search(text):
        return text
    if not CJK_RE.search(text):
        return text
    cleaned = BRACKETED_TRANSLATION_RE.sub("", text)
    return re.sub(r"\s+", " ", cleaned).strip()


def next_lyric_timestamp(entries: list[LyricLine], index: int) -> float | None:
    for next_index in range(index + 1, len(entries)):
        if entries[next_index].text:
            return entries[next_index].timestamp
    return None


def is_credit_line(text: str) -> bool:
    return bool(CREDIT_PREFIX_RE.match(text.strip()))


def should_show_track_label(entries: list[LyricLine], index: int) -> bool:
    current_text = entries[index].text.strip()
    if not is_credit_line(current_text):
        return False

    for previous_index in range(index - 1, -1, -1):
        previous_text = entries[previous_index].text.strip()
        if not previous_text:
            continue
        if not is_credit_line(previous_text):
            return False
    return True


def char_width(char: str) -> int:
    if not char:
        return 0
    if unicodedata.combining(char):
        return 0
    if unicodedata.east_asian_width(char) in {"F", "W"}:
        return 2
    return 1


def display_width(text: str) -> int:
    return sum(char_width(char) for char in text)


def pad_to_width(text: str, columns: int) -> str:
    padding = max(columns - display_width(text), 0)
    return f"{text}{' ' * padding}"


def crop_to_width(text: str, columns: int) -> str:
    if display_width(text) <= columns:
        return text

    trimmed: list[str] = []
    width = 0
    for char in text:
        glyph_width = char_width(char)
        if glyph_width == 0:
            if trimmed:
                trimmed[-1] += char
            continue
        if width + glyph_width > columns:
            break
        trimmed.append(char)
        width += glyph_width

    return "".join(trimmed)


def trim_to_width(text: str, columns: int) -> str:
    return pad_to_width(crop_to_width(text, columns), columns)


def window_from_offset(text: str, columns: int, offset: int) -> str:
    if display_width(text) <= columns:
        return text

    skipped = 0
    start_index = 0
    for index, char in enumerate(text):
        glyph_width = char_width(char)
        if glyph_width == 0:
            continue
        if skipped + glyph_width > offset:
            start_index = index
            break
        skipped += glyph_width
    else:
        start_index = len(text)

    return crop_to_width(text[start_index:], columns)


def lyric_progress_window(
    text: str,
    columns: int,
    line_started_at: float,
    line_ends_at: float | None,
    current_position: float,
) -> str:
    line_width = display_width(text)
    if line_width <= columns:
        return text

    if line_ends_at is None or line_ends_at <= line_started_at:
        return crop_to_width(text, columns)

    overflow = line_width - columns
    progress = (current_position - line_started_at) / (line_ends_at - line_started_at)
    adjusted_progress = progress / 0.82
    clamped_progress = min(max(adjusted_progress, 0.0), 1.0)
    offset = min(math.floor(overflow * clamped_progress), overflow)
    return window_from_offset(text, columns, offset)


def scrolling_window(
    text: str, columns: int, elapsed: float, speed: float, delay: float, gap: str
) -> str:
    if display_width(text) <= columns:
        return text

    if elapsed < delay:
        offset = 0
    else:
        offset = int((elapsed - delay) * speed)

    sequence = list(text + gap)
    start = offset % len(sequence)
    window: list[str] = []
    width = 0
    index = start

    while width < columns:
        char = sequence[index % len(sequence)]
        glyph_width = char_width(char)
        if glyph_width == 0:
            if window:
                window[-1] += char
            index += 1
            continue
        if width + glyph_width > columns:
            break

        window.append(char)
        width += glyph_width
        index += 1

    return "".join(window).rstrip()


def build_status_payload(
    columns: int, speed: float, delay: float, gap: str
) -> dict[str, str]:
    players = list_players()
    states = get_player_states(players)
    selected_player = resolve_selected_player(states)
    has_mpd_player = has_player(players, MPD_PLAYER)
    metadata_player = selected_player.name if selected_player is not None else None
    player_label = (
        player_family(metadata_player) if metadata_player is not None else "none"
    )
    track_label = get_track_label(metadata_player)
    if metadata_player is None:
        return {
            "text": track_label,
            "tooltip": "Player: none\nNo active MPRIS player",
            "class": "stopped",
        }

    status = selected_player.status if selected_player is not None else "Stopped"
    position = get_position(metadata_player, has_mpd_player) or 0.0
    raw_lyrics = None
    if player_family(metadata_player) == MUSICFOX_PLAYER:
        raw_lyrics = playerctl("metadata", "xesam:asText", player=metadata_player)

    lyric_entries = parse_lrc(raw_lyrics) if raw_lyrics else []
    lyric_index = current_lyric_index(lyric_entries, position)
    lyric_line = lyric_entries[lyric_index] if lyric_index is not None else None
    if lyric_index is not None and lyric_line is not None and lyric_line.text:
        if should_show_track_label(lyric_entries, lyric_index):
            return {
                "text": track_label,
                "tooltip": f"Player: {player_label}\n{track_label}",
                "class": "fallback" if status != "Paused" else "paused",
            }

        text = lyric_progress_window(
            lyric_line.text,
            columns=columns,
            line_started_at=lyric_line.timestamp,
            line_ends_at=next_lyric_timestamp(lyric_entries, lyric_index),
            current_position=position,
        )
        return {
            "text": text,
            "tooltip": f"Player: {player_label}\n{track_label}\n{lyric_line.text}",
            "class": "scrolling"
            if display_width(lyric_line.text) > columns
            else "lyrics",
        }

    if player_family(metadata_player) == MUSICFOX_PLAYER:
        text = scrolling_window(
            track_label,
            columns=columns,
            elapsed=position if status == "Playing" else 0.0,
            speed=speed,
            delay=delay,
            gap=gap,
        )
    else:
        text = track_label

    return {
        "text": text,
        "tooltip": f"Player: {player_label}\n{track_label}",
        "class": "fallback" if status != "Paused" else "paused",
    }


def run_action(action: str) -> int:
    states = get_player_states(list_players())
    playerctl_action = "play-pause" if action == "toggle" else action
    selected_player = resolve_selected_player(states)
    if selected_player is None:
        return 1

    result = subprocess.run(
        ["playerctl", "-p", selected_player.name, playerctl_action],
        capture_output=True,
        text=True,
        check=False,
    )
    return 0 if result.returncode == 0 else 1


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Waybar lyrics provider for Musicfox and MPD"
    )
    parser.add_argument(
        "action",
        nargs="?",
        choices=["status", "previous", "next", "toggle"],
        default="status",
    )
    parser.add_argument(
        "--columns", type=int, default=24, help="Visible lyric width in display columns"
    )
    parser.add_argument(
        "--scroll-speed",
        type=float,
        default=2.0,
        help="Scroll speed in characters per second",
    )
    parser.add_argument(
        "--scroll-delay", type=float, default=1.2, help="Delay before scrolling starts"
    )
    parser.add_argument(
        "--gap", default="   ", help="Gap inserted between marquee loops"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.action != "status":
        return run_action(args.action)

    payload = build_status_payload(
        columns=max(args.columns, 4),
        speed=max(args.scroll_speed, 0.1),
        delay=max(args.scroll_delay, 0.0),
        gap=args.gap,
    )
    print(json.dumps(payload, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
