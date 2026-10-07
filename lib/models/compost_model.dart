class CompostModel {
  final String id;
  final String userEmail;
  final String userName;
  final double weight;
  final int points;
  final String imageUrl;
  final String createdAt;
  final String status; // 'pending', 'approved', 'rejected'

  CompostModel({
    required this.id,
    required this.userEmail,
    this.userName = '',
    required this.weight,
    required this.points,
    required this.imageUrl,
    required this.createdAt,
    this.status = 'pending',
  });

  factory CompostModel.fromJson(Map<String, dynamic> json) {
    return CompostModel(
      id: json['id'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userName: json['userName'] ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      points: json['points'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      createdAt: json['createdAt'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'userName': userName,
      'weight': weight,
      'points': points,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'status': status,
    };
  }
}