import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AlarmService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  // Speak + optionally play a sound
  Future<void> triggerAlarm(double distanceKm) async {
    // Text-to-speech announcement
    await _tts.speak(
      'Wake up! You are ${distanceKm.toStringAsFixed(1)} kilometers away from home.',
    );

    // Optionally play a chime (add alarm.mp3 to assets)
    // await _audioPlayer.play(AssetSource('alarm.mp3'));
  }

  Future<void> stopAlarm() async {
    await _tts.stop();
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}