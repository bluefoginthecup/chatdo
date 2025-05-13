// import 'dart:math';
// import 'package:flame/components.dart';
// import 'package:flame/game.dart';
// import '/game/room/girl_sprite.dart';
// import '/game/room/jordy_sprite.dart';
// import 'package:chatdo/chatdo/providers/audio_manager.dart';
//
// class RoomScene extends Component with HasGameRef<FlameGame> {
//   final List<String> bgmList = [
//     'assets/sounds/senti_theme.m4a',
//     'assets/sounds/apple_cider.m4a',
//     'assets/sounds/deliciously_sour.m4a',
//   ];
//
//   late List<String> _bgmQueue;
//
//   @override
//   Future<void> onLoad() async {
//     print('🎮 RoomScene loaded');
//
//     // 리스트 섞어서 큐 초기화
//     _shuffleBgmQueue();
//
//     // 첫 곡은 vilage_theme 고정
//      AudioManager.instance.fadeOutAndPlay(
//       'assets/sounds/vilage_theme.m4a',
//       volume: 0.008,
//       onComplete: _playNextRandomBgm,
//     );
//
//     // 🖼️ 배경 추가
//     add(
//       SpriteComponent(
//         sprite: await gameRef.loadSprite('background.png'),
//         size: gameRef.size,
//         position: Vector2.zero(),
//         priority: -1,
//       ),
//     );
//     print('🎮 background loaded');
//
//     final girl = GirlSprite(position: Vector2(100, 400))..priority = 2;
//     final jordy = JordySprite(position: Vector2(250, 400))..priority = 1;
//
//     add(girl);
//     print('🎮 girl added');
//     add(jordy);
//     print('🎮 jordy added');
//   }
//
//   void _shuffleBgmQueue() {
//     final random = Random();
//     _bgmQueue = List<String>.from(bgmList)..shuffle(random);
//     print('🎵 새로운 BGM 큐: $_bgmQueue');
//   }
//
//   void _playNextRandomBgm() {
//     if (_bgmQueue.isEmpty) {
//       _shuffleBgmQueue(); // 다 돌았으면 다시 셔플
//     }
//
//     final nextBgm = _bgmQueue.removeAt(0);
//     print('🎵 다음 곡 재생: $nextBgm');
//
//     AudioManager.instance.fadeOutAndPlay(
//       nextBgm,
//       volume: 0.02,
//       onComplete: _playNextRandomBgm,
//     );
//   }
// }
