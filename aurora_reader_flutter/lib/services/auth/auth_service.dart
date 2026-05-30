import 'dart:async';

class AuthUser {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime createdAt;

  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        uid: json['uid'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  AuthUser copyWith({String? displayName}) => AuthUser(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        createdAt: createdAt,
      );
}

abstract class AuthService {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<AuthUser> signUp(String email, String password, {String? displayName});
  Future<AuthUser> signIn(String email, String password);
  Future<void> signOut();
  Future<void> updateDisplayName(String name);
  Future<void> deleteAccount();
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
