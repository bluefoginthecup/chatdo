import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GodotView extends StatelessWidget {
  const GodotView({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const UiKitView(
        viewType: 'GodotView', // iOS AppDelegate에서 등록한 ID
        creationParams: null,
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    return const Center(child: Text('iOS에서만 지원됩니다'));
  }
}
