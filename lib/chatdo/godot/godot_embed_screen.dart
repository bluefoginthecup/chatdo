import 'package:flutter/material.dart';
import 'godot_view.dart';

class GodotEmbedScreen extends StatelessWidget {
  const GodotEmbedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Godot (iOS embedded)')),
      body: GodotView(),
    );
  }
}
