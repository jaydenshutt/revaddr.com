/// Reverse-geocode a single lat/lon with RevAddr (Dart 3 / Flutter-friendly).
///
/// Run:
///   export REVADDR_API_KEY=sk_live_...
///   dart pub get
///   dart run bin/reverse.dart
///   dart run bin/reverse.dart 37.7749 -122.4194
///
/// Flutter apps: prefer calling this from your backend. If the client must call
/// RevAddr, inject the key via --dart-define or secure storage (never commit it).
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const defaultBase = 'https://api.revaddr.com';

/// GET /v1/reverse and return the inner result map.
Future<Map<String, dynamic>> reverseGeocode({
  required double lat,
  required double lon,
  required String apiKey,
  String baseUrl = defaultBase,
}) async {
  final root = baseUrl.replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.parse('$root/v1/reverse').replace(
    queryParameters: {
      'lat': lat.toString(),
      'lon': lon.toString(),
    },
  );

  // Auth header: x-api-key (required).
  final response = await http
      .get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'Accept': 'application/json',
        },
      )
      .timeout(const Duration(seconds: 30));

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'HTTP ${response.statusCode}: ${response.body}',
      uri: uri,
    );
  }

  final payload = jsonDecode(response.body) as Map<String, dynamic>;
  final result = payload['result'];
  if (result is! Map<String, dynamic>) {
    throw const FormatException('Unexpected response shape (missing result)');
  }
  return result;
}

Future<void> main(List<String> args) async {
  final apiKey = (Platform.environment['REVADDR_API_KEY'] ?? '').trim();
  if (apiKey.isEmpty) {
    stderr.writeln('Set REVADDR_API_KEY to your RevAddr API key.');
    exitCode = 1;
    return;
  }

  final baseUrl =
      (Platform.environment['REVADDR_BASE_URL'] ?? defaultBase).trim();

  // Website hero default: White House.
  var lat = 38.8977;
  var lon = -77.0365;
  if (args.length >= 2) {
    lat = double.parse(args[0]);
    lon = double.parse(args[1]);
  }

  try {
    final result = await reverseGeocode(
      lat: lat,
      lon: lon,
      apiKey: apiKey,
      baseUrl: baseUrl,
    );
    stdout.writeln(result['formatted_address'] ?? '(no formatted_address)');
    const encoder = JsonEncoder.withIndent('  ');
    stdout.writeln(encoder.convert(result));
  } catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  }
}
