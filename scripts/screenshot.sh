#!/usr/bin/env bash
set -euo pipefail

# NocturnalZone Zedテーマのプレビュー画像（assets/screenshot.png）を再生成する。
# サンプルTypeScriptをZedで開き、ウィンドウを1200x800へ寄せて撮影する。

usage() {
    cat <<'USAGE'
Regenerate assets/screenshot.png (1200x800) from a Zed window showing the sample file.

Usage:
  scripts/screenshot.sh [options]

Options:
  -o, --output-dir DIR  Output directory for screenshot.png. Default: assets/
  -h, --help            Show this help and exit.

Environment:
  ZED_PROCESS_NAME  Process name used for AppleScript window lookup. Default: Zed

Notes:
  - The NocturnalZone theme must already be selected in Zed
    (Zed > Settings > Themes). The script does not switch themes.
  - Window geometry comes from the Accessibility API, so the terminal must be
    allowed to control the computer (System Settings > Privacy & Security >
    Accessibility).
  - The sample file is a temporary copy of scripts/lib/NocturnalZoneSample.ts.
USAGE
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

display_path() {
    local path="$1"
    case "$path" in
    "$repo_root"/*) printf '%s\n' "${path#"$repo_root"/}" ;;
    *) printf '%s\n' "$path" ;;
    esac
}

# 撮影するウィンドウのサイズと位置。
window_width=1200
window_height=800
window_x=60
window_y=60

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"
lib_dir="$script_dir/lib"

output_dir="$repo_root/assets"
process_name="${ZED_PROCESS_NAME:-Zed}"
sample_name="NocturnalZoneSample.ts"

while [ "$#" -gt 0 ]; do
    case "$1" in
    -o | --output-dir)
        [ "$#" -ge 2 ] || die "$1 requires a directory"
        output_dir="$2"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        die "unknown argument: $1"
        ;;
    esac
done

command -v zed >/dev/null 2>&1 || die "zed not found"
command -v osascript >/dev/null 2>&1 || die "osascript not found"
[ -x /usr/sbin/screencapture ] || die "screencapture not found"
[ -f "$lib_dir/$sample_name" ] || die "missing $lib_dir/$sample_name"
[ -f "$lib_dir/activate-app.applescript" ] || die "missing $lib_dir/activate-app.applescript"
[ -f "$lib_dir/window-frame.applescript" ] || die "missing $lib_dir/window-frame.applescript"

tmp_dir=""

cleanup() {
    local status=$?
    if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then
        if [ -x /usr/bin/trash ]; then
            /usr/bin/trash "$tmp_dir" >/dev/null 2>&1 ||
                printf 'warning: could not move %s to Trash\n' "$tmp_dir" >&2
        else
            printf 'warning: /usr/bin/trash not found; leaving %s\n' "$tmp_dir" >&2
        fi
    fi
    return "$status"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

tmp_dir="$(mktemp -d)"
shot="$tmp_dir/screenshot.png"
sample_file="$tmp_dir/$sample_name"
cp "$lib_dir/$sample_name" "$sample_file"

zed "$sample_file"

# ファイルを開いて描画が終わるまでのGUI待ち。到達確認できる状態がないため固定時間だけ待つ。
sleep 3

osascript "$lib_dir/activate-app.applescript" "$process_name" 1 >/dev/null # guardrail-allow: language-delegation

# 利用者の作業中ウィンドウを動かさないよう、サンプル名をタイトルに含むウィンドウだけを対象にする。
osascript "$lib_dir/window-frame.applescript" "$process_name" "$sample_name" set "$window_width" "$window_height" "$window_x" "$window_y" >/dev/null # guardrail-allow: language-delegation

# リサイズ結果が画面へ反映されるまで待つ。
sleep 1

rect="$(osascript "$lib_dir/window-frame.applescript" "$process_name" "$sample_name" get)" # guardrail-allow: language-delegation
case "$rect" in
[0-9]*,[0-9]*,[0-9]*,[0-9]*) ;;
*) die "could not read $process_name window rect: '$rect'" ;;
esac

screencapture -R "$rect" "$shot"
[ -s "$shot" ] || die "screencapture did not write $shot"

mkdir -p "$output_dir"
cp "$shot" "$output_dir/screenshot.png"

printf 'wrote %s (window rect %s)\n' "$(display_path "$output_dir/screenshot.png")" "$rect"
