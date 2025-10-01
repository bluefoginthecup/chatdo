// lib/local_asset_server.dart
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:flutter/services.dart'; // ✅ ByteData, rootBundle 여기 들어있음

class LocalAssetServer {
  HttpServer? _server;
  int? port;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    port = _server!.port;

    _server!.listen((HttpRequest req) async {
      try {
        // 요청 경로 매핑: /assets/... -> Flutter 에셋 경로
        final String path =
            req.uri.path; // e.g. /assets/hilohilo/hilohilo_ios.html
        final String assetPath = path.startsWith('/assets/')
            ? path.substring(1) // "assets/..." 형태로
            : 'assets$path'; // 혹시 "/hilohilo/..."로 오면 "assets/hilohilo/..."로

        final ByteData data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List();

        final contentType = _contentTypeFor(path);
        req.response.headers.set(HttpHeaders.contentTypeHeader, contentType);
        req.response.add(bytes);
        await req.response.close();
      } on PlatformException {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
      } catch (e) {
        req.response.statusCode = HttpStatus.internalServerError;
        await req.response.close();
      }
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  String _contentTypeFor(String path) {
    // 확실히 필요한 것들 우선 강제 지정
    if (path.endsWith('.wasm')) return 'application/wasm';
    if (path.endsWith('.pck')) return 'application/octet-stream';
    if (path.endsWith('.js')) return 'application/javascript; charset=utf-8';
    if (path.endsWith('.html')) return 'text/html; charset=utf-8';
    if (path.endsWith('.css')) return 'text/css; charset=utf-8';
    // 나머지는 mime 패키지로 추론
    return lookupMimeType(path) ?? 'application/octet-stream';
  }
}
