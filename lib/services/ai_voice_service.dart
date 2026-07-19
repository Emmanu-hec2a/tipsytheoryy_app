import 'dart:io';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

enum VoiceState { idle, listening, processing, speaking, error }

class AIVoiceService {
  final _record = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _dio = Dio();
  final ApiClient _apiClient = ApiClient();
  
  String? _currentPath;

  Future<void> startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        _currentPath = '${directory.path}/voice_input.m4a';
        
        const config = RecordConfig(encoder: AudioEncoder.aacLc);
        
        await _record.start(config, path: _currentPath!);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _record.stop();
      return path;
    } catch (e) {
      return null;
    }
  }

  Future<String> transcribe(String path) async {
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(path, filename: "audio.m4a"),
      });
      
      final response = await _apiClient.post('ai/transcribe/', data: formData);
      return response.data['text'] ?? "";
    } catch (e) {
      print("Transcription error: $e");
      return "Error transcribing audio.";
    }
  }

  Future<Map<String, dynamic>> getAIResponse(String userText, {double? lat, double? lng}) async {
    try {
      final response = await _apiClient.post('ai/chat/', data: {
        'message': userText,
        'lat': lat,
        'lng': lng,
      });
      
      return response.data;
    } catch (e) {
      return {
        'text': "I'm having trouble connecting to my spirits. Please try again.",
        'action': null
      };
    }
  }

  Future<void> speak(String text) async {
    try {
      if (text.isEmpty) return;

      // 1. Get TTS URL from backend
      final response = await _apiClient.post('ai/speak/', data: {'text': text});
      final audioUrl = response.data['url'];

      if (audioUrl != null) {
        // 2. Play using URL
        await _audioPlayer.play(UrlSource(audioUrl));
      } else {
        print("TTS Error: No URL returned from backend");
      }
    } catch (e) {
      print("TTS Error in service: $e");
    }
  }

  void dispose() {
    _record.dispose();
    _audioPlayer.dispose();
  }
}
