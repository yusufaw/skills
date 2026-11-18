---
name: bump-version
description: Bump the mobile app's version name via the project's own scripts/bump_version.sh, confirm the target version first, verify both Android and iOS files changed, and draft the release commit message. Use when the user says "bump version", "bump the app version", or /bump-version.
disable-model-invocation: true
---

# bump-version

Wraps the project's `scripts/bump_version.sh`, which sets `versionName` in
`android/app/build.gradle` and `CFBundleShortVersionString` in `ios/Runner/Info.plist`.
The script belongs to the project; this skill never reimplements it.

## Instructions

1. **Check the script exists** at `<project root>/scripts/bump_version.sh`. If it doesn't,
   stop and say so. Don't guess how the project stores its version.
2. **Read the current state** without changing anything:
   ```
   grep -nE 'versionCode|versionName "' android/app/build.gradle
   /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" -c "Print :CFBundleVersion" ios/Runner/Info.plist
   git log --oneline -5 -- android/app/build.gradle ios/Runner/Info.plist
   ```
   If the Android and iOS version names already differ, point that out before bumping.
3. **Confirm the target version.** If the user already gave one (e.g. "bump to 99.8.170"),
   use it. Otherwise ask whether to take the next patch (X.Y.Z+1) or set a specific
   version, since past bumps sometimes skip numbers. Show the recent bumps from the git log
   as context.
4. **Run the script** from the project root:
   ```
   ./scripts/bump_version.sh            # next patch
   ./scripts/bump_version.sh 99.8.170   # explicit
   ```
5. **Verify** by re-reading both values and showing `git diff --stat` plus the changed lines
   of `android/app/build.gradle` and `ios/Runner/Info.plist`. Both must show the new
   version; if one doesn't, say so plainly.
6. **Mention what was left alone**: the build numbers (`versionCode`, `CFBundleVersion`)
   and the `version:` line in `pubspec.yaml`. Report their current values; don't change
   them unless the user asks.
7. **Draft the commit message** in the project's existing format, taken from the git log
   in step 2, e.g.:
   ```
   chore(release): update version to 99.8.170 in build.gradle and Info.plist
   ```
   Only draft it. Don't stage, commit or push: the user drives git.
