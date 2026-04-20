import 'package:dio/dio.dart';
import 'dart:io';

/// API Service for communicating with backend
class ApiService {
  // Android emulator uses 10.0.2.2 to refer to host machine
  // Other platforms use localhost
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );
  }

  // Authentication APIs
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'username': username},
      );
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
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Voice APIs
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
      final response = await _dio.get(
        '/api/voices/my-voices',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
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
      final response = await _dio.post(
        '/api/voices/create',
        data: {'name': name, 'user_defined_name': userDefinedName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
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
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/api/voices/$voiceId/add-sample',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Phase 2: Voice Sample APIs
  Future<Map<String, dynamic>> uploadVoiceSample({
    required int voiceId,
    required String filePath,
    required String token,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      final file = File(filePath);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/api/voice-samples/upload/$voiceId',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onSendProgress: onSendProgress,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> listVoiceSamples({
    required int voiceId,
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/api/voice-samples/list/$voiceId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getVoiceProgress({
    required int voiceId,
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/api/voice-samples/progress/$voiceId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteVoiceSample({
    required int voiceId,
    required String filename,
    required String token,
  }) async {
    try {
      final response = await _dio.delete(
        '/api/voice-samples/delete/$voiceId/$filename',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Phase 3: Voice Conversion APIs
  Future<Map<String, dynamic>> convertVoice({
    required String text,
    required int voiceId,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '/api/voice-conversion/convert',
        data: {'text': text, 'voice_id': voiceId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> downloadAudio({
    required String audioUrl,
    required String savePath,
    required String token,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final fullUrl = '$baseUrl$audioUrl';
      await _dio.download(
        fullUrl,
        savePath,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Voice Preview APIs
  Future<void> playVoicePreview({
    required int voiceId,
    required String token,
    required String savePath,
  }) async {
    try {
      final fullUrl = '$baseUrl/api/voices/$voiceId/preview';
      await _dio.download(
        fullUrl,
        savePath,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  String _handleError(DioException error) {
    if (error.response != null) {
      return error.response?.data['detail'] ?? 'An error occurred';
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Receive timeout';
    } else {
      return error.message ?? 'Unknown error';
    }
  }
}
