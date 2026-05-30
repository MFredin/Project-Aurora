import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'auth_service.dart';

class LocalAuthService implements AuthService {
  static const _usersKey = 'auth_users';
  static const _sessionKey = 'auth_session';
  static const _uuid = Uuid();

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  Box get _box => Hive.box('aurora_reader');

  LocalAuthService() {
    _restoreSession();
  }

  void _restoreSession() {
    final sessionJson = _box.get(_sessionKey) as String?;
    if (sessionJson != null) {
      try {
        final data = jsonDecode(sessionJson) as Map<String, dynamic>;
        _currentUser = AuthUser.fromJson(data);
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  Map<String, dynamic> _loadUsers() {
    final raw = _box.get(_usersKey) as String?;
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    await _box.put(_usersKey, jsonEncode(users));
  }

  int _hashPassword(String email, String password) {
    return '$email:$password'.hashCode;
  }

  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield _currentUser;
    await for (final user in _controller.stream) {
      yield user;
    }
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser> signUp(String email, String password,
      {String? displayName}) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw const AuthException('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    final users = _loadUsers();
    if (users.containsKey(normalizedEmail)) {
      throw const AuthException('An account with this email already exists.');
    }

    final user = AuthUser(
      uid: _uuid.v4(),
      email: normalizedEmail,
      displayName: displayName?.trim(),
      createdAt: DateTime.now(),
    );

    users[normalizedEmail] = {
      ...user.toJson(),
      'passwordHash': _hashPassword(normalizedEmail, password),
    };
    await _saveUsers(users);

    _currentUser = user;
    await _box.put(_sessionKey, jsonEncode(user.toJson()));
    _controller.add(user);

    return user;
  }

  @override
  Future<AuthUser> signIn(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw const AuthException('Please enter your email address.');
    }

    final users = _loadUsers();
    final userData = users[normalizedEmail];

    if (userData == null) {
      throw const AuthException('No account found with this email.');
    }

    final storedHash = userData['passwordHash'] as int;
    if (storedHash != _hashPassword(normalizedEmail, password)) {
      throw const AuthException('Incorrect password.');
    }

    final user = AuthUser.fromJson(userData as Map<String, dynamic>);
    _currentUser = user;
    await _box.put(_sessionKey, jsonEncode(user.toJson()));
    _controller.add(user);

    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _box.delete(_sessionKey);
    _controller.add(null);
  }

  @override
  Future<void> updateDisplayName(String name) async {
    if (_currentUser == null) {
      throw const AuthException('Not signed in.');
    }

    _currentUser = _currentUser!.copyWith(displayName: name.trim());

    final users = _loadUsers();
    final email = _currentUser!.email;
    if (users.containsKey(email)) {
      users[email] = {
        ...users[email] as Map<String, dynamic>,
        'displayName': _currentUser!.displayName,
      };
      await _saveUsers(users);
    }

    await _box.put(_sessionKey, jsonEncode(_currentUser!.toJson()));
    _controller.add(_currentUser);
  }

  @override
  Future<void> deleteAccount() async {
    if (_currentUser == null) {
      throw const AuthException('Not signed in.');
    }

    final users = _loadUsers();
    users.remove(_currentUser!.email);
    await _saveUsers(users);

    _currentUser = null;
    await _box.delete(_sessionKey);
    _controller.add(null);
  }
}
