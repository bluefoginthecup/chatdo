// lib/hilohilo_game_view.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../local_asset_server.dart';

class HilohiloGameView extends StatefulWidget {
  const HilohiloGameView({super.key});

  @override
  State<HilohiloGameView> createState() => _HilohiloGameViewState();
}

class _HilohiloGameViewState extends State<HilohiloGameView> {
  late final WebViewController _controller;
  final _server = LocalAssetServer();

  @override
  void initState() {
    super.initState();
    final params = const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(onWebResourceError: (e) {
          debugPrint('Web error: ${e.errorCode} ${e.description}');
        }),
      );
    _boot();
  }

  Future<void> _boot() async {
    await _server.start();

    // Godot HTML이 참조하는 경로와 일치시키기 위해 /assets/로 시작하도록 접속
    final url =
    Uri.parse('http://127.0.0.1:${_server.port}/assets/hilohilo/hilohilo_ios.html');

    await _controller.loadRequest(url);
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hilo Hilo')),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
