#!/usr/bin/env bash
set -euo pipefail

fail() { printf 'Installation failed: %s\n' "$*" >&2; exit 1; }
[[ $# == 2 ]] || fail 'Usage: bash scripts/install.sh macos|linux <package>'
platform=$1
[[ -f "$2" ]] || fail "Package not found: $2"
package=$(cd "$(dirname "$2")" && printf '%s/%s' "$(pwd -P)" "$(basename "$2")")
work=$(mktemp -d "${TMPDIR:-/tmp}/abacus-install.XXXXXX")
trap 'rm -rf "$work"' EXIT

case "$platform" in
    macos)
        [[ $(uname -s) == Darwin ]] || fail 'Install the macOS package on macOS'
        [[ $(id -u) != 0 ]] || fail 'Run without sudo: the macOS package installs for the current user'
        app="$HOME/Applications/Abacus.app"
        [[ ! -e "$app" && ! -L "$app" ]] || fail "Refusing to replace existing $app; move it aside first"
        pkgutil --expand-full "$package" "$work/expanded"
        component="$work/expanded/abacus-component.pkg"
        source_app="$component/Payload/Abacus.app"
        [[ -d "$source_app" && ! -e "$component/Scripts" ]] || fail 'Expected script-free Abacus component is missing'
        [[ $(xmllint --xpath 'string(/pkg-info/@identifier)' "$component/PackageInfo") == io.github.prankerborislavchik.abacus ]] || fail 'Unexpected package identifier'
        distribution="$work/expanded/Distribution"
        [[ $(xmllint --xpath 'string(/installer-gui-script/domains/@enable_currentUserHome)' "$distribution") == true ]] || fail 'Package must enable current-user installation'
        [[ $(xmllint --xpath 'string(/installer-gui-script/domains/@enable_localSystem)' "$distribution") == false ]] || fail 'Package must disable system installation'
        [[ $(xmllint --xpath 'string(/installer-gui-script/domains/@enable_anywhere)' "$distribution") == false ]] || fail 'Package must disable other volume installation'
        [[ $(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$source_app/Contents/Info.plist") == io.github.prankerborislavchik.abacus ]] || fail 'Unexpected app bundle identifier'
        codesign --verify --deep --strict "$source_app"
        installer -pkg "$package" -target CurrentUserHomeDirectory -verboseR
        [[ -x "$app/Contents/MacOS/Abacus" && -d "$app/Contents/Frameworks/App.framework" && -d "$app/Contents/Frameworks/FlutterMacOS.framework" ]] || fail 'Installed app is incomplete'
        codesign --verify --deep --strict "$app"
        diff -qr --no-dereference "$source_app" "$app"
        pkgutil --volume "$HOME" --pkg-info io.github.prankerborislavchik.abacus
        printf 'Installed executable: %s/Contents/MacOS/Abacus\n' "$app"
        ;;
    linux)
        [[ $(uname -s) == Linux ]] || fail 'Install the Linux package on Linux'
        [[ $(dpkg-deb --field "$package" Package) == abacus ]] || fail 'Unexpected package name'
        if dpkg-query -W -f='${Status}' abacus 2>/dev/null | grep -q 'install ok installed'; then
            fail 'Abacus is already installed; remove it with apt first to run a clean-install check'
        fi
        [[ ! -e /opt/abacus && ! -L /opt/abacus && ! -e /usr/bin/abacus && ! -L /usr/bin/abacus ]] || fail 'Refusing to overwrite an existing Abacus directory or command'
        expected_version=$(dpkg-deb --field "$package" Version)
        # apt resolves declared dependencies; dpkg --unpack alone would not.
        if [[ $(id -u) == 0 ]]; then
            apt-get install --yes "$package"
        else
            sudo apt-get install --yes "$package"
        fi
        [[ $(dpkg-query -W -f='${Version}' abacus) == "$expected_version" ]] || fail 'Installed version does not match package'
        [[ $(dpkg-query -W -f='${Status}' abacus) == 'install ok installed' ]] || fail 'Package is not configured'
        [[ -x /opt/abacus/abacus && -f /opt/abacus/lib/libapp.so && -f /opt/abacus/lib/libflutter_linux_gtk.so && -f /opt/abacus/data/icudtl.dat && -d /opt/abacus/data/flutter_assets ]] || fail 'Installed app is incomplete'
        [[ $(readlink /usr/bin/abacus) == /opt/abacus/abacus && -f /usr/share/applications/abacus.desktop ]] || fail 'Desktop integration is incomplete'
        dpkg --verify abacus
        printf 'Installed executable: /opt/abacus/abacus\n'
        ;;
    *) fail "Unknown platform: $platform (use macos or linux)" ;;
esac
