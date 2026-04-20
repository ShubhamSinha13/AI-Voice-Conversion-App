import 'package:flutter/services.dart';

/// Native method channel for audio capture and voice conversion
class AudioCaptureChannel {
  static const platform = MethodChannel('com.voiceconverter.app/audio');

  /// Start audio capture for call
  static Future<bool> startCapture() async {
    try {
      final bool result = await platform.invokeMethod('startCapture');
      return result;
    } catch (e) {
      print('Error starting capture: $e');
      return false;
    }
  }

  /// Stop audio capture
  static Future<bool> stopCapture() async {
    try {
      final bool result = await platform.invokeMethod('stopCapture');
      return result;
    } catch (e) {
      print('Error stopping capture: $e');
      return false;
    }
  }

  /// Get current audio level (0-100)
  static Future<int> getAudioLevel() async {
    try {
      final int level = await platform.invokeMethod('getAudioLevel');
      return level;
    } catch (e) {
      print('Error getting audio level: $e');
      return 0;
    }
  }

  /// Check if audio capture is active
  static Future<bool> isCapturing() async {
    try {
      final bool capturing = await platform.invokeMethod('isCapturing');
      return capturing;
    } catch (e) {
      print('Error checking capture status: $e');
      return false;
    }
  }

  /// Set target voice for conversion
  static Future<bool> setTargetVoice(String voiceId, String embedding) async {
    try {
      final bool result = await platform.invokeMethod(
        'setTargetVoice',
        {'voiceId': voiceId, 'embedding': embedding},
      );
      return result;
    } catch (e) {
      print('Error setting target voice: $e');
      return false;
    }
  }
}
