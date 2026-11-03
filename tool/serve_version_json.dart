// Serves the server's version.json (server/songs/version.json, the nginx web
// root) over plain HTTP so the in-app update flow can be exercised without
// deploying anything.
//
// Run from the repository root:
//
//   dart run tool/serve_version_json.dart
//
// Then start a debug build pointed at it:
//
//   flutter run --dart-define=UPDATE_CONFIG_URL=http://127.0.0.1:8099/version.json
//
// On a USB-connected Android device, forward the port first:
//
//   adb reverse tcp:8099 tcp:8099
//
// The manifest is re-read on every request, so version.json can be edited while
// the server is running and the next check in the app picks up the change.

import 'dart:convert';
import 'dart:io';

const String _defaultFile = 'server/songs/version.json';
const int _defaultPort = 8099;

const String _usage = '''
Usage: dart run tool/serve_version_json.dart [--port <port>] [--file <path>]

  --port <port>   Port to listen on (default: $_defaultPort)
  --file <path>   Manifest to serve (default: $_defaultFile, relative to the
                  current directory)
  -h, --help      Show this help
''';

typedef _Options = ({int port, String file});

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options == null) return;

  final manifest = File(options.file);
  if (!manifest.existsSync()) {
    stderr.writeln('No manifest at ${manifest.absolute.path}');
    stderr.writeln('Run this from the repository root, or pass --file <path>.');
    exitCode = 1;
    return;
  }

  final HttpServer server;
  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, options.port);
  } on SocketException catch (error) {
    stderr.writeln(
      'Cannot listen on 127.0.0.1:${options.port}: ${error.message}',
    );
    stderr.writeln('Pass --port to use a different port.');
    exitCode = 1;
    return;
  }

  final url = 'http://127.0.0.1:${server.port}/version.json';
  stdout.writeln('Serving ${manifest.absolute.path}');
  stdout.writeln('  Manifest:    $url');
  stdout.writeln(
    '  Android USB: adb reverse tcp:${server.port} tcp:${server.port}',
  );
  stdout.writeln('  Debug build: flutter run --dart-define=UPDATE_CONFIG_URL=$url');
  stdout.writeln('Edits apply on the next request. Ctrl+C to stop.');

  await for (final request in server) {
    await _respond(request, manifest);
  }
}

Future<void> _respond(HttpRequest request, File manifest) async {
  final response = request.response;
  response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');

  if (request.uri.path != '/version.json') {
    await _writeText(
      response,
      HttpStatus.notFound,
      'This server only serves /version.json.\n',
    );
    stdout.writeln('404 ${request.uri.path}');
    return;
  }

  final String body;
  try {
    body = await manifest.readAsString();
    jsonDecode(body); // Fail loudly here instead of in the app's silent catch.
  } on FormatException catch (error) {
    await _writeText(
      response,
      HttpStatus.internalServerError,
      'version.json is not valid JSON: ${error.message}\n',
    );
    stderr.writeln('500 ${request.uri.path} → invalid JSON: ${error.message}');
    return;
  } on FileSystemException catch (error) {
    await _writeText(
      response,
      HttpStatus.internalServerError,
      'Could not read ${manifest.path}: ${error.message}\n',
    );
    stderr.writeln('500 ${request.uri.path} → ${error.message}');
    return;
  }

  response.statusCode = HttpStatus.ok;
  response.headers.contentType = ContentType.json;
  response.write(body);
  await response.close();
  stdout.writeln(
    '200 ${request.uri.path} (${utf8.encode(body).length} bytes)',
  );
}

Future<void> _writeText(
  HttpResponse response,
  int statusCode,
  String body,
) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.text;
  response.write(body);
  await response.close();
}

_Options? _parseArgs(List<String> args) {
  var port = _defaultPort;
  var file = _defaultFile;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '-h' || '--help':
        stdout.write(_usage);
        return null;
      case '--port':
        if (i + 1 >= args.length) {
          stderr.write('--port needs a value.\n\n$_usage');
          exitCode = 1;
          return null;
        }
        final value = int.tryParse(args[++i]);
        if (value == null || value < 1 || value > 65535) {
          stderr.write('Invalid port: ${args[i]}\n\n$_usage');
          exitCode = 1;
          return null;
        }
        port = value;
      case '--file':
        if (i + 1 >= args.length) {
          stderr.write('--file needs a value.\n\n$_usage');
          exitCode = 1;
          return null;
        }
        file = args[++i];
      default:
        stderr.write('Unknown argument: ${args[i]}\n\n$_usage');
        exitCode = 1;
        return null;
    }
  }

  return (port: port, file: file);
}
