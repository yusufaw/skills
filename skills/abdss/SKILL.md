---
name: abdss
description: Take a screenshot of the connected Android device via adb, save it to the desktop, and load the latest screenshot into the chat. Use when the user types "abdss" or asks to screenshot their Android device.
disable-model-invocation: true
allowed-tools: Bash(adb *) Bash(mkdir *) Bash(ls *)
---

## Capture screenshot

!`mkdir -p ~/Desktop/android-screenshots && adb exec-out screencap -p > ~/Desktop/android-screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png && echo "Captured."`

## Latest screenshot path

!`ls -t ~/Desktop/android-screenshots/*.png 2>/dev/null | head -1`

## Instructions

The path printed above under "Latest screenshot path" is the file just captured.
Use the Read tool to open that exact file so its image loads into this conversation.

If the capture command failed or no path was printed, tell the user to check `adb devices` — the device needs USB debugging enabled and to be authorized.
