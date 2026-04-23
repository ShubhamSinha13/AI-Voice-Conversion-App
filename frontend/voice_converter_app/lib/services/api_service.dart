import 'package:dio/dio.dart';
import 'dart:io';

class ApiService {
  static String get baseUrl {
    return Platform.isAndroid
        ? 'http://10.0.2.2:8001'
        : 'http://localhost:8001';
  }

  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'username': username,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio
          .post('/auth/login', data: {'email': email, 'password': password});
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getPredefinedVoices() async {
    try {
      final response = await _dio.get('/api/voices/predefined');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMyVoices({required String token}) async {
    try {
      final response = await _dio.get('/api/voices/my-voices',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createVoice({
    required String name,
    required String userDefinedName,
    required String token,
  }) async {
    try {
      final response = await _dio.post('/api/voices/create',
          data: {'name': name, 'user_defined_name': userDefinedName},
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> playVoicePreview({
    required int voiceId,
    required String token,
    required String savePath,
  }) async {
    try {
      await _dio.download('$baseUrl/api/voices/$voiceId/preview', savePath,
          options: Options(headers: {'Authorization': 'Bearer $token'}));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> convertAudioFile({
    required int voiceId,
    required String audioFilePath,
    required String token,
    required String savePath,
  }) async {
    try {
      final multipartFile = await MultipartFile.fromFile(audioFilePath);
      final formData = FormData.fromMap({'file': multipartFile});
      final response = await _dio.post('/api/voices/$voiceId/convert',
          data: formData,
          options: Options(
              headers: {'Authorization': 'Bearer $token'},
              responseType: ResponseType.stream));
      if (response.statusCode == 200 || response.statusCode == null) {
        final audioBytes = <int>[];
        await for (var chunk in response.data.stream) {
          audioBytes.addAll(chunk);
        }
        final file = File(savePath);
        await file.writeAsBytes(audioBytes);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> convertAudioFileML({
    required int voiceId,
    required String audioFilePath,
    required String token,
    required String savePath,
  }) async {
    try {
      final multipartFile = await MultipartFile.fromFile(audioFilePath);
      final formData = FormData.fromMap({'file': multipartFile});
      final response = await _dio.post('/api/voices/$voiceId/convert-ml',
          data: formData,
          options: Options(
              headers: {'Authorization': 'Bearer $token'},
              responseType: ResponseType.stream));
      if (response.statusCode == 200 || response.statusCode == null) {
        final audioBytes = <int>[];
        await for (var chunk in response.data.stream) {
          audioBytes.addAll(chunk);
        }
        final file = File(savePath);
        await file.writeAsBytes(audioBytes);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> convertAudioFileRVC({
    required int voiceId,
    required String audioFilePath,
    required String token,
    required String savePath,
    String quality = 'balanced',
  }) async {
    try {
      final multipartFile = await MultipartFile.fromFile(audioFilePath);
      final formData = FormData.fromMap({'file': multipartFile});
      final response = await _dio.post(
          '/api/voices/$voiceId/convert-rvc?quality=$quality',
          data: formData,
          options: Options(
              headers: {'Authorization': 'Bearer $token'},
              responseType: ResponseType.stream));
      if (response.statusCode == 200 || response.statusCode == null) {
        final audioBytes = <int>[];
        await for (var chunk in response.data.stream) {
          audioBytes.addAll(chunk);
        }
        final file = File(savePath);
        await file.writeAsBytes(audioBytes);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> downloadAudio({
    required String audioUrl,
    required String savePath,
    required String token,
  }) async {
    try {
      await _dio.download('$baseUrl$audioUrl', savePath,
          options: Options(headers: {'Authorization': 'Bearer $token'}));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadVoiceSample({
    required int voiceId,
    required String filePath,
    required String token,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData =
          FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
      final response = await _dio.post('/api/voice-samples/upload/$voiceId',
          data: formData,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
          onSendProgress: onSendProgress);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addVoiceSample({
    required int voiceId,
    required String filePath,
    required String token,
  }) async {
    try {
      final formData =
          FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
      final response = await _dio.post('/api/voices/$voiceId/add-sample',
          data: formData,
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> convertVoice({
    required String text,
    required int voiceId,
    required String token,
  }) async {
    try {
      final response = await _dio.post('/api/voice-conversion/convert',
          data: {'text': text, 'voice_id': voiceId},
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map) {
        return data['detail'] ?? 'An error occurred';
      } else if (data is String) {
        return data;
      }
    }
    return error.message ?? 'Unknown error';
  }
}
