#!/usr/bin/env bash
# Fetch a revision into a new checkout, then build, test, package and install it.
set -euo pipefail

usage() {
  cat <<'HELP'
Usage: bash scripts/ci.sh [options]

  --repository URL   Git remote URL or local repository (default: public Abacus)
  --ref REF          Branch, tag or commit to fetch (default: main)
  --target OS        macos, windows or linux (default: current OS)
  --work-dir PATH    New directory for checkout and evidence (default: temporary)
  --system-flutter   Use Flutter on PATH, verifying it matches .fvmrc
  --help            Show this help

The default SDK command is fvm flutter. Build tools must already be installed.
This command installs Abacus on this computer; the install scripts refuse to
replace an existing installation. The checkout and logs are kept for review.
HELP
}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
hash_package() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | tee "$evidence/package-sha256.txt"
  else
    shasum -a 256 "$1" | tee "$evidence/package-sha256.txt"
  fi
}
run() { printf '\n>'; printf ' %q' "$@"; printf '\n'; "$@"; }

repository=https://github.com/prankerborislavchik/abacus.git
ref=main
target=
work_dir=
system_flutter=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repository|--ref|--target|--work-dir)
      [[ $# -ge 2 && -n "$2" ]] || fail "Missing value for $1"
      case "$1" in
        --repository) repository=$2 ;;
        --ref) ref=$2 ;;
        --target) target=$2 ;;
        --work-dir) work_dir=$2 ;;
      esac
      shift 2 ;;
    --system-flutter) system_flutter=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) fail "Unknown option: $1 (see --help)" ;;
  esac
done
[[ "$ref" != -* ]] || fail "Ref cannot start with '-'"

case "$(uname -s)" in
  Darwin) host_target=macos ;;
  Linux) host_target=linux ;;
  MINGW*|MSYS*|CYGWIN*) host_target=windows ;;
  *) fail "Unsupported host; use macOS, Linux or Git Bash on Windows" ;;
esac
target=${target:-$host_target}
case "$target" in macos|windows|linux) ;; *) fail "Unknown target: $target" ;; esac
[[ "$target" == "$host_target" ]] || fail "Native $target builds require a $target host (current: $host_target)"
command -v git >/dev/null || fail "Git is required"
if "$system_flutter"; then
  command -v flutter >/dev/null || fail "Flutter is missing from PATH"
  flutter_command=(flutter)
else
  command -v fvm >/dev/null || fail "FVM is required (or use --system-flutter)"
  flutter_command=(fvm flutter)
fi
if [[ "$target" == windows ]]; then
  command -v pwsh >/dev/null || fail "PowerShell 7 (pwsh) is required on Windows"
fi

if [[ -z "$work_dir" ]]; then
  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/abacus-ci.XXXXXX")
else
  [[ ! -e "$work_dir" ]] || fail "Work directory already exists: $work_dir"
  mkdir -p "$(dirname "$work_dir")"
  mkdir "$work_dir"
fi
work_dir=$(cd "$work_dir" && pwd -P)
evidence="$work_dir/evidence"
checkout="$work_dir/source"
mkdir "$evidence"
exec > >(tee -a "$evidence/pipeline.log") 2>&1
finish() {
  status=$?
  printf 'exit_code=%s\nfinished_at=%s\n' "$status" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$evidence/run.txt"
  printf '\nPipeline exit code: %s\nEvidence: %s\nCheckout: %s\n' "$status" "$evidence" "$checkout"
}
trap finish EXIT
printf 'target=%s\nrequested_ref=%s\nstarted_at=%s\n' "$target" "$ref" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$evidence/run.txt"
printf 'Fresh checkout: %s\n' "$checkout"
# Do not reset or clean the checkout from which this script was started.
run git clone --no-checkout -- "$repository" "$checkout"
cd "$checkout"
run git fetch --no-tags origin "$ref"
run git checkout --detach FETCH_HEAD
printf 'commit=%s\n' "$(git rev-parse HEAD)" >> "$evidence/run.txt"
run git log -1 --format=fuller

[[ -f .fvmrc ]] || fail "Fetched revision has no .fvmrc"
expected_version=$(awk -F '"' '/"flutter"/ { print $4; exit }' .fvmrc)
[[ -n "$expected_version" ]] || fail "Cannot read Flutter version from .fvmrc"
if ! "$system_flutter"; then run fvm install; fi
"${flutter_command[@]}" --version | tee "$evidence/flutter-version.txt"
actual_version=$(awk '$1 == "Flutter" { print $2; exit }' "$evidence/flutter-version.txt")
[[ "$actual_version" == "$expected_version" ]] || fail "Flutter $actual_version does not match .fvmrc ($expected_version)"
run "${flutter_command[@]}" pub get --enforce-lockfile
run "${flutter_command[@]}" build "$target" --release
run "${flutter_command[@]}" test --reporter expanded | tee "$evidence/tests.log"

case "$target" in
  macos|linux)
    run bash scripts/package.sh "$target"
    extension=pkg
    [[ "$target" != linux ]] || extension=deb
    package="$checkout/dist/abacus-$target.$extension"
    hash_package "$package"
    run bash scripts/install.sh "$target" "$package"
    run bash scripts/ci-smoke.sh "$target" "$evidence" ;;
  windows)
    run pwsh -NoProfile -File scripts/package-windows.ps1
    hash_package dist/abacus-windows-setup.exe
    # Relative paths avoid MSYS argument conversion for PowerShell parameters.
    run pwsh -NoProfile -File scripts/install-windows.ps1 -PackagePath dist/abacus-windows-setup.exe
    run pwsh -NoProfile -File scripts/ci-smoke-windows.ps1 -EvidenceDirectory ../evidence ;;
esac
printf '\nBuild, tests, package, installation and process smoke check passed.\n'
