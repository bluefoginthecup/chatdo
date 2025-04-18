import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../flame/room_game.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: RoomGame());
  }
}
