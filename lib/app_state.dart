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

  // Роль текущего пользователя
  String get role => _currentUser?.role ?? '';
  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  AppState() {
    _init();
  }

  // Инициализация — проверяем, залогинен ли пользователь
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

  // Вход
  Future<String?> login(String email, String password) async {
    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      notifyListeners();
      return null; // null = успех
    } catch (e) {
      return e.toString(); // возвращаем текст ошибки
    }
  }

  // Регистрация
  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? schoolId,
  }) async {
    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        schoolId: schoolId,
      );
      notifyListeners();
      return null; // null = успех
    } catch (e) {
      return e.toString();
    }
  }

  // Выход
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // Обновить данные текущего пользователя
  void updateCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
}