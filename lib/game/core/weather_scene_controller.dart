import '/chatdo/data/weather_repository.dart';
import 'package:chatdo/game/components/speech_bubble_component.dart';
import 'package:flame/components.dart';
import 'package:chatdo/game/room/jordy_sprite.dart';



class WeatherSceneController {
  final WeatherRepository _repository = WeatherRepository();

  /// 날씨 정보를 불러와서 말풍선과 배경에 반영
  Future<void> applyWeatherToRoom({
    required SpriteComponent backgroundComponent,
    required SpeechBubbleComponent speechBubble,
  }) async {
    try {
      final (text, bgImagePath) = await _repository.getTodayWeather();
      print('[Weather] applyWeatherToRoom called');

      // 말풍선 텍스트 업데이트
      speechBubble.updateText(text);


      // ✅ 기존 대사 앞에 날씨 끼워넣기
      if (speechBubble.attachedTo is JordySprite) {
        final jordy = speechBubble.attachedTo as JordySprite;
        final originalDialogues = jordy.dialogueList;
        if (originalDialogues.isEmpty || originalDialogues.first != text) {
          jordy.dialogueList = [text, ...originalDialogues];
        }
      }


      // 배경 이미지 업데이트
      final newSprite = await Sprite.load(bgImagePath);
      backgroundComponent.sprite = newSprite;
    }
    catch (e, stack) {
      print('[Weather] ❌ ERROR: $e');
      print('[Weather] ❌ STACK: $stack');

      speechBubble.updateText('날씨 정보를 불러오지 못했어요.');
    }
  }
}
