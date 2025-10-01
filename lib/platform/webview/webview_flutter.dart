import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HilohiloGameView extends StatefulWidget {
  const HilohiloGameView({super.key});

  @override
  State<HilohiloGameView> createState() => _HilohiloGameViewState();
}

class _HilohiloGameViewState extends State<HilohiloGameView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final params = const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onWebResourceError: (error) {
          debugPrint('Web error: ${error.errorCode} ${error.description}');
        },
      ))
      ..loadFlutterAsset('assets/hilohilo/index.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
