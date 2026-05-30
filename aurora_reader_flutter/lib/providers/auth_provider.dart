import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/local_auth_service.dart';
import '../services/auth/firebase_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirebaseAuthService();
  }
  return LocalAuthService();
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).value;
});
