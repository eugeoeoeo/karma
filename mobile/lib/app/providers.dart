import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

// ─── Auth State ─────────────────────────────────────────────────────────────────

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? error;
  final bool aiAvailable;

  const AuthState({this.status = AuthStatus.initial, this.user, this.error, this.aiAvailable = true});

  AuthState copyWith({AuthStatus? status, Map<String, dynamic>? user, String? error, bool? aiAvailable}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      aiAvailable: aiAvailable ?? this.aiAvailable,
    );
  }
}

// ─── Auth Notifier ──────────────────────────────────────────────────────────────

class AuthNotifier extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _api = ApiClient();
  AuthState _state = const AuthState();

  AuthState get state => _state;

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        final response = await _api.get('/user/profile');
        if (response.data['success'] == true) {
          _state = _state.copyWith(status: AuthStatus.authenticated, user: response.data['data']);
          _checkAIStatus();
          notifyListeners();
          return;
        }
      } catch (_) {}
    }
    _state = _state.copyWith(status: AuthStatus.unauthenticated);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _state = _state.copyWith(status: AuthStatus.loading, error: null);
    notifyListeners();
    try {
      final response = await _api.post('/auth/login', data: {'email': email, 'password': password});
      if (response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.write(key: 'access_token', value: data['accessToken']);
        await _storage.write(key: 'refresh_token', value: data['refreshToken']);
        _state = _state.copyWith(status: AuthStatus.authenticated, user: data['user']);
        _checkAIStatus();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _state = _state.copyWith(status: AuthStatus.unauthenticated, error: _parseError(e));
      notifyListeners();
    }
    return false;
  }

  Future<bool> register(String email, String username, String password) async {
    _state = _state.copyWith(status: AuthStatus.loading, error: null);
    notifyListeners();
    try {
      final response = await _api.post('/auth/register', data: {'email': email, 'username': username, 'password': password});
      if (response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.write(key: 'access_token', value: data['accessToken']);
        await _storage.write(key: 'refresh_token', value: data['refreshToken']);
        _state = _state.copyWith(status: AuthStatus.authenticated, user: data['user']);
        _checkAIStatus();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _state = _state.copyWith(status: AuthStatus.unauthenticated, error: _parseError(e));
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    try { await _api.post('/auth/logout', data: {'refreshToken': refreshToken}); } catch (_) {}
    await _storage.deleteAll();
    _state = const AuthState(status: AuthStatus.unauthenticated);
    notifyListeners();
  }

  Future<void> _checkAIStatus() async {
    try {
      final response = await _api.get('/ai/status');
      if (response.data['success'] == true) {
        _state = _state.copyWith(aiAvailable: response.data['data']['available'] == true);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> refreshProfile() async {
    try {
      final response = await _api.get('/user/profile');
      if (response.data['success'] == true) {
        _state = _state.copyWith(user: response.data['data']);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> updateProfile(String username) async {
    _state = _state.copyWith(status: AuthStatus.loading, error: null);
    notifyListeners();
    try {
      final response = await _api.patch('/user/profile', data: {'username': username});
      if (response.data['success'] == true) {
        _state = _state.copyWith(status: AuthStatus.authenticated, user: response.data['data']);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _state = _state.copyWith(status: AuthStatus.authenticated, error: _parseError(e));
      notifyListeners();
    }
    return false;
  }

  Future<void> resetAIStatus() async {
    try {
      final response = await _api.post('/ai/status/reset');
      if (response.data['success'] == true) {
        _state = _state.copyWith(aiAvailable: response.data['data']['available'] == true);
        notifyListeners();
      }
    } catch (_) {}
  }

  String _parseError(dynamic e) {
    // Show detailed debug errors during development
    if (e is DioException) {
      final url = e.requestOptions.uri.toString();
      final statusCode = e.response?.statusCode;

      // Server returned an error response
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map && data['error'] != null) {
          return '[${statusCode}] ${data['error']} (URL: $url)';
        }
        if (data is Map && data['message'] != null) {
          return '[${statusCode}] ${data['message']} (URL: $url)';
        }
        return '[$statusCode] Server error (URL: $url)';
      }

      // Network/timeout errors - show full debug info
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return 'TIMEOUT connecting to: $url';
        case DioExceptionType.receiveTimeout:
          return 'TIMEOUT receiving from: $url';
        case DioExceptionType.sendTimeout:
          return 'TIMEOUT sending to: $url';
        case DioExceptionType.connectionError:
          return 'CONNECTION ERROR to: $url\n${e.message ?? "No details"}';
        default:
          return 'DIO ERROR [${e.type}]: ${e.message}\nURL: $url';
      }
    }
    return 'ERROR: ${e.runtimeType}: $e';
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────────

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) => AuthNotifier());

// Dashboard data provider
final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await ApiClient().get('/dashboard');
  return response.data['data'];
});

// User virtues
final userVirtuesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final response = await ApiClient().get('/virtues/user');
  return response.data['data'];
});

// Actions
final actionsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, page) async {
  final response = await ApiClient().get('/actions', queryParameters: {'page': page, 'limit': 20});
  return response.data['data'];
});

// Intentions
final intentionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final response = await ApiClient().get('/intentions');
  return response.data['data'];
});

// Blessings
final blessingsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, page) async {
  final response = await ApiClient().get('/blessings', queryParameters: {'page': page});
  return response.data['data'];
});

// Reflections
final reflectionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final response = await ApiClient().get('/reflections');
  return response.data['data'];
});

// Story chapters
final storyProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final response = await ApiClient().get('/story');
  return response.data['data'];
});

// Mentor history
final mentorHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final response = await ApiClient().get('/mentor/history');
  return response.data['data'];
});

// User stats
final statsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await ApiClient().get('/user/stats');
  return response.data['data'];
});

// AI status
final aiStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await ApiClient().get('/ai/status');
  return response.data['data'];
});

// Wishes
final wishesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final response = await ApiClient().get('/wishes');
  return response.data['data'];
});

