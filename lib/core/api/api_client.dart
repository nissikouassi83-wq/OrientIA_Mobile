import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // 10.0.2.2 = émulateur Android | 192.168.1.125 = téléphone réel sur Wi-Fi
  static const String _baseUrl = 'http://192.168.1.125:8000/api';

  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) => handler.next(error),
    ));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await _dio.post('/auth/token/', data: {'email': email, 'password': password});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final r = await _dio.post('/auth/google/', data: {'id_token': idToken});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String username, String email, String password, String password2) async {
    final r = await _dio.post('/auth/register/', data: {
      'username': username,
      'email': email,
      'password': password,
      'password2': password2,
    });
    return r.data as Map<String, dynamic>;
  }

  // ── Profil ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMe() async {
    final r = await _dio.get('/me/');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final r = await _dio.patch('/me/', data: data);
    return r.data as Map<String, dynamic>;
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard() async {
    final r = await _dio.get('/dashboard/stats/');
    return r.data as Map<String, dynamic>;
  }

  // ── Recommandations ───────────────────────────────────────────────────────
  Future<List<dynamic>> getRecommendations() async {
    final r = await _dio.get('/recommendations/');
    final data = r.data;
    if (data is Map) return (data['results'] as List?) ?? [];
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getRecommendationDetail(int jobId) async {
    final r = await _dio.get('/recommendations/$jobId/');
    return r.data as Map<String, dynamic>;
  }

  // ── Plan de carrière ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getCareerPlan() async {
    final r = await _dio.get('/career-plan/');
    return r.data as Map<String, dynamic>;
  }

  // ── Coach IA ──────────────────────────────────────────────────────────────
  Future<List<dynamic>> getCoachMessages() async {
    final r = await _dio.get('/coach/messages/');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendCoachMessage(String content) async {
    final r = await _dio.post('/coach/messages/', data: {'content': content});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCoachProgram() async {
    final r = await _dio.get('/coach/program/');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCoachActionPlan() async {
    final r = await _dio.get('/coach/action-plan/');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createCoachActionPlan(Map<String, dynamic> data) async {
    final r = await _dio.post('/coach/action-plan/', data: data);
    return r.data as Map<String, dynamic>;
  }

  // ── Métiers ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTrendingCareers({
    String? country,
    String? education,
    bool? remote,
    String? search,
  }) async {
    final r = await _dio.get('/careers/trending/', queryParameters: {
      if (country != null && country != 'ALL') 'country': country,
      if (education != null && education != 'ALL') 'education_level': education,
      if (remote == true) 'remote': true,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return r.data as Map<String, dynamic>;
  }

  // ── Reconversion ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getReconversionOptions({
    String? currentField,
    List<String>? skills,
  }) async {
    final r = await _dio.post('/reconversion/options/', data: {
      if (currentField != null) 'current_field': currentField,
      if (skills != null) 'skills': skills,
    });
    return r.data as Map<String, dynamic>;
  }

  // ── Gap Analysis ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getGapAnalysis(int jobId) async {
    final r = await _dio.get('/gap-analysis/$jobId/');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTrainingRecommendations(int jobId, {String? platform}) async {
    final r = await _dio.get('/gap-analysis/training-recommendations/', queryParameters: {
      'job_id': jobId,
      if (platform != null && platform != 'ALL') 'platform': platform,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLearningPaths(int jobId) async {
    final r = await _dio.get('/gap-analysis/learning-paths/', queryParameters: {'job_id': jobId});
    return r.data as Map<String, dynamic>;
  }

  // ── CV ────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadCv(String filePath) async {
    final formData = FormData.fromMap({'cv': await MultipartFile.fromFile(filePath)});
    final r = await _dio.post('/cv/upload/', data: formData);
    return r.data as Map<String, dynamic>;
  }

  // ── Psychométrie ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> startPsychometricSession(String type) async {
    final r = await _dio.post('/psychometric/sessions/', data: {
      'assessment_type': type,
      'user_preferences': {'language': 'fr', 'difficulty_preference': 'adaptive'},
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdaptiveQuestion(String sessionId) async {
    final r = await _dio.get('/psychometric/questions/adaptive_next/',
        queryParameters: {'session_id': sessionId});
    return r.data as Map<String, dynamic>;
  }

  Future<void> submitPsychometricResponse({
    required String sessionId,
    required int questionId,
    required int value,
    required double responseTime,
  }) async {
    await _dio.post('/psychometric/responses/', data: {
      'session_id': sessionId,
      'question': questionId,
      'response_value': value,
      'response_time': responseTime,
    });
  }

  Future<Map<String, dynamic>> getPsychometricProfile() async {
    final r = await _dio.get('/psychometric/profiles/my_profile/');
    return r.data as Map<String, dynamic>;
  }
}
