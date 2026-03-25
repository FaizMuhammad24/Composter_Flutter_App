class AppNotificationModel {
  final String id;
  final String userEmail; 
  final String title;
  final String message;
  final String type; // 'success', 'error', 'reward', 'system'
  final bool isRead;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.userEmail,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] ?? '',
      userEmail: json['userEmail'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppNotificationModel copyWith({
    String? id,
    String? userEmail,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
