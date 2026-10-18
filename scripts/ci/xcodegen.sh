#!/usr/bin/env bash
# Generates Erase.xcodeproj from project.yml with a pinned XcodeGen release.
set -euo pipefail

version="${XCODEGEN_VERSION:-2.46.0}"
dir="${RUNNER_TEMP:-/tmp}/xcodegen-$version"

if [[ ! -x "$dir/xcodegen/bin/xcodegen" ]]; then
	mkdir -p "$dir"
	curl -fsSL "https://github.com/yonaskolb/XcodeGen/releases/download/$version/xcodegen.zip" -o "$dir/xcodegen.zip"
	unzip -q "$dir/xcodegen.zip" -d "$dir"
fi

"$dir/xcodegen/bin/xcodegen" generate --spec project.yml
