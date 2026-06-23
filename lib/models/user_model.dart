class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin', atau 'user'
  final int? points; // null untuk admin, int untuk user
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.points,
    required this.createdAt,
    this.lastLogin,
  });

  // Cek role
  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  // Convert dari Map/JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      points: json['points'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
    );
  }

  // Convert ke Map/JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'points': points,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  // Copy with
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    int? points,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
