---
name: flutter-netlog
description: Inspect the network requests of a running Flutter debug app (URLs, status, headers, full request/response bodies) by reading the dart:io HTTP profile over the VM service, the same data as DevTools' Network tab, with no proxy and no app code changes. Use when the user asks to check, inspect or log the app's network/API requests, verify what payload was sent, or says "netlog".
---

# flutter-netlog

Reads the HTTP profile that every Flutter debug build already keeps (Dio, GetConnect and
`package:http` all go through `dart:io`'s `HttpClient`). Nothing is added to the app.

## Setup (once per machine)

The CLI lives in `scripts/` next to this file. Resolve its deps once, offline is fine since
`vm_service` ships in the Flutter pub cache:

```
cd <this skill folder>/scripts && dart pub get --offline
```

## Instructions

1. **The user runs the app, not you.** Hand them the run command with
   `--vmservice-out-file=build/vm_uri.txt` added, e.g.
   `fvm flutter run -d <device> --vmservice-out-file=build/vm_uri.txt`.
   `build/` is normally gitignored, so the file doesn't dirty the repo.
   If the project has run scripts that forward extra flags, append the flag to those instead.
2. Pick the Dart binary that matches the project: `<project>/.fvm/flutter_sdk/bin/dart` if it
   exists, otherwise `dart`.
3. Run every command from `<this skill folder>/scripts`, passing the absolute path of the
   project's `build/vm_uri.txt`:

   ```
   dart run bin/netlog.dart <project>/build/vm_uri.txt enable
   dart run bin/netlog.dart <project>/build/vm_uri.txt list [url-substring]
   dart run bin/netlog.dart <project>/build/vm_uri.txt show <id>
   dart run bin/netlog.dart <project>/build/vm_uri.txt clear
   ```

4. Recording is off by default and resets on every launch and hot restart (not hot reload).
   Every command switches it back on when it's off and prints a `note: recording was off`
   line to stderr. When you see that note, tell the user to repeat the action, since
   anything before it wasn't captured. Run `enable` up front when the user is about to test.
5. To find a request, `list` with a URL fragment, and filter writes with
   `| grep -E " (POST|PUT|PATCH|DELETE) "`. `show` output can be long (full bodies), so
   redirect it to a scratch file and grep for the fields you need.
6. Report what was sent and what came back: the exact field values, the status, and, when
   it matters, the follow-up GET showing what the server stored. Convert UTC timestamps to
   the user's timezone (the `x-user-timezone` header if present) when dates are involved.

## Notes

- Debug/profile builds only; release builds don't expose the VM service.
- The `Authorization` header is redacted in `show` output; keep it that way.
- If the app was relaunched, `build/vm_uri.txt` is overwritten with the new address, so
  nothing else changes. If it's missing, the app was started without the flag.
