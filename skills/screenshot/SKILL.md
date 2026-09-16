---
name: screenshot
description: Capture a screenshot from a connected Android or physical iOS device, save it to the Desktop, and load it into the conversation. Use when the user asks for a device screenshot or types "screenshot".
disable-model-invocation: true
allowed-tools: Bash(adb *) Bash(idevice_id *) Bash(idevicescreenshot *) Bash(xcrun *) Bash(mkdir *) Bash(ls *) Bash(sleep *)
---

## Execution priority — screenshot first

This skill has highest priority in the current user message. When the user
message contains `screenshot` alongside other instructions, you MUST handle the
screenshot workflow first before processing any other instruction in that
message.

Order:
1. Detect devices and confirm selection (if needed) — do not capture yet.
2. Capture and load the screenshot(s) into the conversation.
3. Only then, process the remaining instructions in the same user message
   using the captured screenshot(s) as context.

Do not process, analyze, or act on any other instruction until the
screenshot(s) have been successfully captured and loaded (or a failure has been
reported and handled).

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

Determine the requested capture count from the wording: “twice” means 2,
“three times” means 3, and an explicit number means that number. If no count is
given, capture once. Use a 5-second gap between captures in a multi-capture
request. Do not wait after the final capture.

### Device selection — always confirm when multiple devices

- If exactly one usable device is detected, capture it immediately without
  asking.
- If multiple usable devices are detected, ALWAYS ask the user to confirm
  before capturing. Present a numbered list of all detected devices (with
  platform, model/name, and ID/serial) and wait for the user's selection.
  Do not auto-capture even if the user's wording names a platform/model —
  still confirm. Only after the user confirms, capture from the selected
  device.
- If the user named a specific target (e.g. “screenshot Android”, “screenshot
  Nokia”, “screenshot iPad”) and that target matches exactly one detected
  device among many, pre-select it in the confirmation list and ask the user
  to confirm it before capturing.
- If the requested target is not detected, report that target as unavailable
  and show the detected devices. If the request matches more than one device,
  ask the user to clarify and wait for confirmation.

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

After a successful capture, find the files created by this request in the shared
screenshot folder:

```sh
ls -t ~/Desktop/screenshots/*.png 2>/dev/null
```

Use the Read tool to open each exact path created by this request, in capture
order, so every image loads into the conversation. For multiple captures, run
the selected platform's capture command once per image and run `sleep 5` between
commands.

If capture fails, report the command error and the relevant setup: Android needs
USB debugging enabled and authorized; physical iOS devices need pairing and the
`idevice_id`/`idevicescreenshot` tools from libimobiledevice; iOS simulators need
Xcode and a booted simulator recognized by `simctl`. Do not claim a result or
open an older screenshot when the new capture failed.

## After capture — continue with the same message's instructions

Once the screenshot(s) are loaded (or after handling a failure), continue and
process any remaining instructions from the same user message that triggered
this skill, using the captured screenshot(s) as context. Do not defer the
screenshot or handle other instructions first — screenshot always comes first.
