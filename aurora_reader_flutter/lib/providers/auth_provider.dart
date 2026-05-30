import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/local_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return LocalAuthService();
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
