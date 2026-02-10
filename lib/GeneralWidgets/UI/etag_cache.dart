import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EtagCacheEntry {
  final String? etag;
  final dynamic json;

  const EtagCacheEntry({required this.etag, required this.json});
}

/// Lightweight local ETag + JSON cache using SharedPreferences.
///
/// Caching key is the full request URL (including query params), per user
/// instruction: store `etag` + `json` for each endpoint URL.
class EtagCache {
  static const String _prefix = 'etag_cache_v1:';

  static String _keyForUrl(String url) => '$_prefix$url';

  static Future<EtagCacheEntry?> read(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForUrl(url));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return EtagCacheEntry(
        etag: decoded['etag'] as String?,
        json: decoded['json'],
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(
    String url, {
    String? etag,
    required dynamic json,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({'etag': etag, 'json': json});
    await prefs.setString(_keyForUrl(url), payload);
  }
}

String buildDioCacheUrl(
  Dio dio,
  String path,
  Map<String, dynamic>? queryParameters,
) {
  final baseUrl = dio.options.baseUrl;
  final full = (baseUrl.endsWith('/') && path.startsWith('/'))
      ? '${baseUrl.substring(0, baseUrl.length - 1)}$path'
      : '$baseUrl$path';

  final uri = Uri.parse(full);
  if (queryParameters == null || queryParameters.isEmpty) return uri.toString();

  // SharedPreferences key needs stable ordering: sort keys.
  final qp = <String, String>{};
  final keys = queryParameters.keys.toList()..sort((a, b) => a.compareTo(b));
  for (final k in keys) {
    final v = queryParameters[k];
    if (v == null) continue;
    qp[k] = v.toString();
  }

  return uri
      .replace(queryParameters: {...uri.queryParameters, ...qp})
      .toString();
}

/// GET with ETag/304 caching:
/// - Sends `If-None-Match` when we have a stored ETag
/// - On 200: stores response JSON + ETag (if provided)
/// - On 304: returns stored JSON without parsing body
Future<dynamic> dioGetWithEtagCache({
  required Dio dio,
  required String path,
  Map<String, dynamic>? queryParameters,
  required Map<String, String> headers,
}) async {
  final cacheUrl = buildDioCacheUrl(dio, path, queryParameters);
  final cached = await EtagCache.read(cacheUrl);

  final requestHeaders = <String, String>{...headers};
  final cachedEtag = cached?.etag;
  if (cachedEtag != null && cachedEtag.trim().isNotEmpty) {
    requestHeaders['If-None-Match'] = cachedEtag;
  }

  Response<dynamic> response = await dio.get(
    path,
    queryParameters: queryParameters,
    options: Options(
      headers: requestHeaders,
      validateStatus: (status) {
        if (status == null) return false;
        return (status >= 200 && status < 300) || status == 304;
      },
    ),
  );

  // Cache miss but server returned 304: retry once without ETag.
  if (response.statusCode == 304 && cached == null) {
    response = await dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        validateStatus: (status) {
          if (status == null) return false;
          return status >= 200 && status < 300;
        },
      ),
    );
  }

  if (response.statusCode == 304) {
    return cached!.json;
  }

  final etag = response.headers.value('etag') ?? response.headers.value('ETag');
  await EtagCache.write(cacheUrl, etag: etag, json: response.data);
  return response.data;
}
