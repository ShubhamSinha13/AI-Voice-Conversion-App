import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

/// Auth state provider
class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  }) : isAuthenticated = user != null && token != null;

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Auth notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  /// Update loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set error message
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Set authenticated user with token
  void setAuthenticated(User user, String token) {
    state = AuthState(
      user: user,
      token: token,
      isLoading: false,
      error: null,
    );
  }

  /// Clear authentication
  void logout() {
    state = AuthState();
  }

  /// Update user profile
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Get current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Get auth token
final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).token;
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
