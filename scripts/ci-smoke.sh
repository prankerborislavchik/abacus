#!/usr/bin/env bash
# Bounded startup check of the installed application, not a UI interaction test.
set -euo pipefail
[[ $# == 2 ]] || { printf 'Usage: %s macos|linux EVIDENCE_DIRECTORY\n' "$0" >&2; exit 1; }
target=$1
evidence=$2
case "$target" in
  macos) executable="$HOME/Applications/Abacus.app/Contents/MacOS/Abacus" ;;
  linux)
    executable=/opt/abacus/abacus
    if [[ -z "${DISPLAY:-}" ]]; then
      command -v xvfb-run >/dev/null || { printf 'xvfb-run is required without DISPLAY\n' >&2; exit 1; }
      exec xvfb-run -a bash "$0" "$target" "$evidence"
    fi ;;
  *) printf 'Unsupported smoke-check target: %s\n' "$target" >&2; exit 1 ;;
esac
[[ -x "$executable" ]] || { printf 'Installed executable is missing: %s\n' "$executable" >&2; exit 1; }
mkdir -p "$evidence"
printf 'executable=%s\n' "$executable" > "$evidence/smoke.txt"
"$executable" > "$evidence/application.log" 2>&1 &
app_pid=$!
cleanup() {
  if kill -0 "$app_pid" 2>/dev/null; then
    kill "$app_pid" 2>/dev/null || true
    for _ in 1 2 3; do
      kill -0 "$app_pid" 2>/dev/null || break
      sleep 1
    done
    if kill -0 "$app_pid" 2>/dev/null; then
      kill -KILL "$app_pid" 2>/dev/null || true
    fi
  fi
  wait "$app_pid" 2>/dev/null || true
}
trap cleanup EXIT
printf 'pid=%s\n' "$app_pid" >> "$evidence/smoke.txt"
for _ in 1 2 3 4 5; do
  sleep 1
  if ! kill -0 "$app_pid" 2>/dev/null; then
    printf 'Installed application exited during startup.\n' >&2
    cat "$evidence/application.log" >&2
    exit 1
  fi
done
ps -p "$app_pid" -o pid=,comm= >> "$evidence/smoke.txt"
printf 'alive_after_seconds=5\nresult=passed\n' >> "$evidence/smoke.txt"
printf 'Installed application remained alive for five seconds: %s\n' "$executable"
