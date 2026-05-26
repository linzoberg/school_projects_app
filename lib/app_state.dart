import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  String get role => _currentUser?.role ?? '';
  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  AppState() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _currentUser = await _authService.getUserById(firebaseUser.uid);
      } else {
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // -------------------------------------------------------
  // Вход
  // -------------------------------------------------------
  Future<String?> login(String email, String password) async {
    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // -------------------------------------------------------
  // Регистрация — сразу устанавливаем пользователя
  // -------------------------------------------------------
  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? schoolId,
  }) async {
    try {
      final newUser = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        schoolId: schoolId,
      );

      if (newUser != null) {
        // Сразу устанавливаем пользователя — не ждём слушателя
        _currentUser = newUser;
        _isLoading = false;
        notifyListeners();
      }

      return null; // null = успех
    } catch (e) {
      return e.toString();
    }
  }

  // -------------------------------------------------------
  // Выход
  // -------------------------------------------------------
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // -------------------------------------------------------
  // Обновить профиль пользователя
  // -------------------------------------------------------
  void updateCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // -------------------------------------------------------
  // Обновить профиль в БД и локально
  // -------------------------------------------------------
  Future<void> updateCurrentUserProfile(UserModel user) async {
    await _authService.updateUserProfile(user);
    _currentUser = user;
    notifyListeners();
  }
}