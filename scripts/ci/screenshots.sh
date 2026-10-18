#!/usr/bin/env bash
# Installs the simulator build and captures every tab, in Russian dark and English light.
# Usage: screenshots.sh <path/to/Erase.app> <output dir>
set -euo pipefail

app="$1"
out="$2"
bundle="com.erasemc.app"
screens=(home leaderboards tiers account search)

mkdir -p "$out"

# The newest iOS runtime, on the first iPhone Pro it offers (falls back to any iPhone).
udid=$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
def version(runtime):
    return [int(n) for n in re.findall(r"\d+", runtime.split("iOS-")[-1])]
runtimes = sorted((r for r in devices if "iOS" in r and devices[r]), key=version, reverse=True)
for runtime in runtimes:
    phones = [d for d in devices[runtime] if d["name"].startswith("iPhone")]
    pro = [d for d in phones if "Pro" in d["name"] and "Max" not in d["name"]]
    if pro or phones:
        pick = (pro or phones)[0]
        print(pick["udid"])
        print(pick["name"], runtime, file=sys.stderr)
        break
')

xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b
xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
xcrun simctl install "$udid" "$app"

# Two combinations cover both languages and both themes at half the frames.
for combo in ru:dark en:light; do
	language="${combo%%:*}"
	appearance="${combo##*:}"
	{
		xcrun simctl ui "$udid" appearance "$appearance"
		for screen in "${screens[@]}"; do
			xcrun simctl launch --terminate-running-process "$udid" "$bundle" \
				-screen "$screen" -AppleLanguages "($language)" -AppleLocale "$language" >/dev/null
			# Network-backed screens need a moment to load and settle their animations.
			sleep 4
			xcrun simctl io "$udid" screenshot --type=png "$out/$language-$appearance-$screen.png" >/dev/null
		done
		# Pushed screens open through a launch argument; `simctl openurl` leaves a system prompt on screen.
		xcrun simctl launch --terminate-running-process "$udid" "$bundle" 			-screen home -route "erasemc://player/khaoslxng" -AppleLanguages "($language)" -AppleLocale "$language" >/dev/null
		sleep 6
		xcrun simctl io "$udid" screenshot --type=png "$out/$language-$appearance-player.png" >/dev/null
	}
done

ls -1 "$out"
