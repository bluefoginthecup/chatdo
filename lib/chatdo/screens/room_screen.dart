import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '/game/components/flame/room_game.dart';

class RoomScreen extends StatelessWidget {
  final RoomGame roomGame;

  const RoomScreen({super.key, required this.roomGame});

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: roomGame);
  }


}

