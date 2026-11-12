// Reads the dart:io HTTP profile (same data as DevTools' Network tab) from a running debug app.
//
// Usage (from this scripts/ folder): dart run bin/netlog.dart <vm-service-uri-or-file> <command> [arg]
//   enable          start recording (every other command also does this if it's off)
//   list [filter]   list recorded requests, optionally filtered by URL substring
//   show <id>       full headers + bodies of one request
//   clear           drop recorded requests
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('usage: netlog <uri|file> enable|list [filter]|show <id>|clear');
    exit(64);
  }
  final service = await vmServiceConnectUri(_wsUri(args[0]));
  try {
    final isolateId = await _appIsolate(service);
    // Recording resets on every launch/hot restart, so switch it back on whenever it's found off
    final state = await service.httpEnableTimelineLogging(isolateId);
    if (!state.enabled) {
      await service.httpEnableTimelineLogging(isolateId, true);
      if (args[1] != 'enable') {
        stderr.writeln('note: recording was off (app restarted?), enabled it now; repeat the action to capture it');
      }
    }
    switch (args[1]) {
      case 'enable':
        print('HTTP profiling enabled on $isolateId');
      case 'clear':
        await service.clearHttpProfile(isolateId);
        print('cleared');
      case 'list':
        final filter = args.length > 2 ? args[2] : '';
        final profile = await service.getHttpProfile(isolateId);
        final requests = profile.requests.where((r) => r.uri.toString().contains(filter)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        for (final r in requests) {
          final status = r.response?.statusCode ?? (r.request?.hasError == true ? 'ERR' : '...');
          final ms = r.endTime == null ? '' : '${r.endTime!.difference(r.startTime).inMilliseconds}ms';
          print('${r.id.padRight(6)} ${r.startTime.toLocal().toIso8601String().substring(11, 23)} '
              '${r.method.padRight(6)} $status ${ms.padLeft(7)}  ${r.uri}');
        }
        print('${requests.length} request(s)');
      case 'show':
        final r = await service.getHttpProfileRequest(isolateId, args[2]);
        print('${r.method} ${r.uri}');
        print('status: ${r.response?.statusCode}  started: ${r.startTime.toLocal()}');
        print('\n--- request headers ---');
        r.request?.headers?.forEach((k, v) => print('$k: ${_redact(k, v)}'));
        print('\n--- request body ---\n${_body(r.requestBody)}');
        print('\n--- response headers ---');
        r.response?.headers?.forEach((k, v) => print('$k: $v'));
        print('\n--- response body ---\n${_body(r.responseBody)}');
      default:
        stderr.writeln('unknown command ${args[1]}');
        exit(64);
    }
  } finally {
    await service.dispose();
  }
}

String _wsUri(String arg) {
  final raw = File(arg).existsSync() ? File(arg).readAsStringSync().trim() : arg;
  final uri = Uri.parse(raw);
  final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
  return uri.replace(scheme: 'ws', path: path.endsWith('ws/') ? path : '${path}ws').toString();
}

Future<String> _appIsolate(VmService service) async {
  final vm = await service.getVM();
  for (final ref in vm.isolates ?? <IsolateRef>[]) {
    final isolate = await service.getIsolate(ref.id!);
    if (isolate.extensionRPCs?.contains('ext.dart.io.getHttpProfile') ?? false) return ref.id!;
  }
  throw StateError('no isolate exposes the HTTP profile (is this a debug build?)');
}

String _redact(String key, Object? value) =>
    key.toLowerCase() == 'authorization' ? '<redacted>' : '$value';

String _body(List<int>? bytes) {
  if (bytes == null || bytes.isEmpty) return '(empty)';
  final text = utf8.decode(bytes, allowMalformed: true);
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
  } catch (_) {
    return text.length > 4000 ? '${text.substring(0, 4000)}\n... (${text.length} chars)' : text;
  }
}
