import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  // Экземпляры Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Текущий пользователь Firebase
  User? get currentFirebaseUser => _auth.currentUser;

  // Поток изменений состояния авторизации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // -------------------------------------------------------
  // Регистрация нового пользователя
  // -------------------------------------------------------
  Future<UserModel?> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? schoolId,
  }) async {
    try {
      // Создаём аккаунт в Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Создаём профиль пользователя в Firestore
      final userModel = UserModel(
        id: uid,
        email: email,
        displayName: displayName,
        role: role,
        schoolId: schoolId,
        createdAt: DateTime.now(),
      );

      await _db
          .collection('users')
          .doc(uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // -------------------------------------------------------
  // Вход существующего пользователя
  // -------------------------------------------------------
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      return await getUserById(uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // -------------------------------------------------------
  // Выход из аккаунта
  // -------------------------------------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  // -------------------------------------------------------
  // Получить данные пользователя по id
  // -------------------------------------------------------
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------
  // Получить текущего пользователя (из Firestore)
  // -------------------------------------------------------
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return await getUserById(firebaseUser.uid);
  }

  // -------------------------------------------------------
  // Обновить профиль пользователя
  // -------------------------------------------------------
  Future<void> updateUserProfile(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.id)
        .update(user.toMap());
  }

  // -------------------------------------------------------
  // Перевод ошибок Firebase в понятный текст
  // -------------------------------------------------------
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован';
      case 'invalid-email':
        return 'Некорректный формат email';
      case 'weak-password':
        return 'Пароль должен содержать не менее 6 символов';
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение к интернету';
      default:
        return 'Ошибка авторизации: ${e.message}';
    }
  }
}