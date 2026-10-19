#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
fail() { printf 'Packaging failed: %s\n' "$*" >&2; exit 1; }
require() { command -v "$1" >/dev/null || fail "Required command is missing: $1"; }
[[ $# == 1 ]] || fail 'Usage: bash scripts/package.sh macos|linux (after a release build)'
platform=$1
version=$(sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+\+[0-9]+)[[:space:]]*$/\1/p' "$ROOT/pubspec.yaml")
[[ -n "$version" ]] || fail 'pubspec.yaml must contain version: MAJOR.MINOR.PATCH+BUILD'
release=${version%+*}
build=${version#*+}
DIST="$ROOT/dist"
mkdir -p "$DIST"
work=$(mktemp -d "${TMPDIR:-/tmp}/abacus-package.XXXXXX")
trap 'rm -rf "$work"' EXIT

case "$platform" in
    macos)
        [[ $(uname -s) == Darwin ]] || fail 'Build the macOS package on macOS'
        for command in pkgbuild productbuild pkgutil codesign ditto lipo; do require "$command"; done
        app="$ROOT/build/macos/Build/Products/Release/Abacus.app"
        [[ -x "$app/Contents/MacOS/Abacus" ]] || fail 'Run fvm flutter build macos --release first'
        plist="$app/Contents/Info.plist"
        [[ $(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist") == io.github.prankerborislavchik.abacus ]] || fail 'Unexpected app bundle identifier'
        [[ $(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist") == "$release" ]] || fail 'Release build version does not match pubspec.yaml; rebuild'
        [[ $(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist") == "$build" ]] || fail 'Release build number does not match pubspec.yaml; rebuild'
        codesign --verify --deep --strict "$app"
        minimum_os=$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$plist")
        [[ "$minimum_os" =~ ^[0-9]+(\.[0-9]+)*$ ]] || fail 'Invalid minimum macOS version in app'
        architectures=$(lipo -archs "$app/Contents/MacOS/Abacus")
        case "$architectures" in
            arm64|x86_64) ;;
            'arm64 x86_64'|'x86_64 arm64') architectures=arm64,x86_64 ;;
            *) fail "Unsupported executable architectures: $architectures" ;;
        esac
        mkdir "$work/payload"
        ditto "$app" "$work/payload/Abacus.app"
        pkgbuild --root "$work/payload" \
            --component-plist "$ROOT/packaging/macos/components.plist" \
            --identifier io.github.prankerborislavchik.abacus \
            --version "$release.$build" --install-location /Applications \
            "$work/abacus-component.pkg"
        sed -e "s/@VERSION@/$version/g" -e "s/@PACKAGE_VERSION@/$release.$build/g" \
            -e "s/@ARCH@/$architectures/g" -e "s/@MIN_OS@/$minimum_os/g" \
            "$ROOT/packaging/macos/Distribution.xml.in" > "$work/Distribution.xml"
        productbuild --distribution "$work/Distribution.xml" --package-path "$work" "$work/abacus-macos.pkg"
        mv "$work/abacus-macos.pkg" "$DIST/abacus-macos.pkg"
        pkgutil --payload-files "$DIST/abacus-macos.pkg" > "$DIST/abacus-macos-files.txt"
        (cd "$DIST" && shasum -a 256 abacus-macos.pkg > abacus-macos.pkg.sha256)
        ;;
    linux)
        [[ $(uname -s) == Linux ]] || fail 'Build the Linux package on Linux'
        for command in dpkg-deb dpkg-shlibdeps sha256sum; do require "$command"; done
        case "$(uname -m)" in
            x86_64) architecture=amd64; flutter_arch=x64 ;;
            aarch64) architecture=arm64; flutter_arch=arm64 ;;
            *) fail 'Only x86_64 and aarch64 Linux builds are supported' ;;
        esac
        bundle="$ROOT/build/linux/$flutter_arch/release/bundle"
        [[ -x "$bundle/abacus" && -f "$bundle/lib/libapp.so" && -f "$bundle/lib/libflutter_linux_gtk.so" && -f "$bundle/data/icudtl.dat" && -d "$bundle/data/flutter_assets" ]] || fail 'Run fvm flutter build linux --release first'
        stage="$work/stage"
        mkdir -p "$stage/opt/abacus" "$stage/DEBIAN" "$stage/usr/bin" "$stage/usr/share/applications" "$stage/usr/share/icons/hicolor/256x256/apps" "$work/debian"
        cp -a "$bundle/." "$stage/opt/abacus/"
        ln -s /opt/abacus/abacus "$stage/usr/bin/abacus"
        cp "$ROOT/packaging/linux/abacus.desktop" "$stage/usr/share/applications/"
        cp "$ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png" "$stage/usr/share/icons/hicolor/256x256/apps/abacus.png"
        # Inspect every shipped ELF shared library as well as the runner. Bundled
        # Flutter libraries have no Debian shlibs metadata; system libraries do.
        printf 'Source: abacus\nSection: utils\nPriority: optional\nMaintainer: Abacus contributors <noreply@github.com>\n\nPackage: abacus\nArchitecture: any\nDescription: Desktop calculator\n' > "$work/debian/control"
        elf_args=(-e"$bundle/abacus")
        while IFS= read -r library; do elf_args+=(-e"$library"); done < <(find "$bundle/lib" -type f -name '*.so*')
        dependencies=$(cd "$work" && dpkg-shlibdeps --ignore-missing-info -O -l"$bundle/lib" "${elf_args[@]}")
        dependencies=${dependencies#shlibs:Depends=}
        [[ -n "$dependencies" && "$dependencies" != *$'\n'* ]] || fail 'Could not determine Linux runtime dependencies'
        cat > "$stage/DEBIAN/control" <<EOF
Package: abacus
Version: $version
Section: utils
Priority: optional
Architecture: $architecture
Maintainer: Abacus contributors <noreply@github.com>
Depends: $dependencies
Installed-Size: $(du -sk "$stage/opt/abacus" | awk '{print $1}')
Homepage: https://github.com/prankerborislavchik/abacus
Description: Calculator for mathematical expressions
 Desktop calculator with trigonometry, expression editing and calculator memory.
EOF
        dpkg-deb --root-owner-group --build "$stage" "$work/abacus-linux.deb"
        mv "$work/abacus-linux.deb" "$DIST/abacus-linux.deb"
        dpkg-deb --contents "$DIST/abacus-linux.deb" > "$DIST/abacus-linux-files.txt"
        dpkg-deb --info "$DIST/abacus-linux.deb" > "$DIST/abacus-linux-info.txt"
        (cd "$DIST" && sha256sum abacus-linux.deb > abacus-linux.deb.sha256)
        ;;
    *) fail "Unknown platform: $platform (use macos or linux)" ;;
esac
printf 'Package complete: %s/abacus-%s\n' "$DIST" "$platform"
