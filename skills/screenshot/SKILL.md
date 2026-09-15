---
name: screenshot
description: Capture a screenshot from a connected Android or physical iOS device, save it to the Desktop, and load it into the conversation. Use when the user asks for a device screenshot or types "screenshot".
disable-model-invocation: true
allowed-tools: Bash(adb *) Bash(idevice_id *) Bash(idevicescreenshot *) Bash(xcrun *) Bash(mkdir *) Bash(ls *)
---

## Find the connected devices

Check both device families before capturing:

```sh
adb devices -l
idevice_id -l
xcrun simctl list devices booted
```

If a command is unavailable, treat that source as having no detected devices and
continue checking the others. If `simctl` reports an operation-permitted or
CoreSimulatorService connection error, retry the same check with the required
macOS access before treating simulators as unavailable.

Treat only Android rows whose state is `device` as available. Treat each UDID
printed by `idevice_id -l` as an available physical iOS device. Treat only
booted simulator rows from `xcrun simctl list devices booted` as available iOS
simulators. Ignore Android rows in `offline` or `unauthorized` state and report
those states if there are no usable devices.

Use the user's wording to select a device automatically when it names a platform,
model, device name, or device ID. For example, “screenshot Android”, “screenshot
Nokia”, and “screenshot iPad” should target the matching connected device without
asking the user to choose. Match platform and device names case-insensitively;
prefer an exact device ID or model match when available.

If the requested target is not detected, report that target as unavailable and
show the detected devices. If the request matches more than one device, ask the
user to clarify. If the request does not name a target and there is exactly one
usable device, capture it immediately. Only ask the user to choose from a
numbered list when the request has no target and multiple usable devices exist.

## Capture the selected device

For Android, create a timestamped file in the shared screenshot directory and
target the selected serial explicitly:

```sh
mkdir -p ~/Desktop/screenshots && adb -s <ANDROID_SERIAL> exec-out screencap -p > ~/Desktop/screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png && echo "Captured."
```

For physical iOS, create a timestamped file in the same directory and target the
selected UDID:

```sh
mkdir -p ~/Desktop/screenshots && idevicescreenshot -u <IOS_UDID> ~/Desktop/screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png && echo "Captured."
```

For an iOS simulator, use its booted simulator UDID:

```sh
mkdir -p ~/Desktop/screenshots && xcrun simctl io <SIMULATOR_UDID> screenshot ~/Desktop/screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png && echo "Captured."
```

## Load the result

After a successful capture, find the newest file in the shared screenshot
folder:

```sh
ls -t ~/Desktop/screenshots/*.png 2>/dev/null | head -1
```

Use the Read tool to open the exact path printed for the capture so the image
loads into the conversation, matching the `adbss` skill's result behavior.

If capture fails, report the command error and the relevant setup: Android needs
USB debugging enabled and authorized; physical iOS devices need pairing and the
`idevice_id`/`idevicescreenshot` tools from libimobiledevice; iOS simulators need
Xcode and a booted simulator recognized by `simctl`. Do not claim a result or
open an older screenshot when the new capture failed.
