class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String role; // student, teacher, admin
  final String? schoolId;
  final String? photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.schoolId,
    this.photoUrl,
    required this.createdAt,
  });

  // Создание объекта из Map (из Firebase)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'student',
      schoolId: map['schoolId'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  // Преобразование объекта в Map (для сохранения в Firebase)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'schoolId': schoolId,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Копирование с изменёнными полями
  UserModel copyWith({
    String? displayName,
    String? role,
    String? schoolId,
    String? photoUrl,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}