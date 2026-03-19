/// 🎁 Reward Model (Updated) - Aplikasi Monitoring Kompos
/// Model untuk katalog reward yang bisa ditukar dengan poin

class RewardModel {
  final String id;
  final String name;
  final String description;
  final int points;
  final String category;
  final String imageUrl;
  final String createdBy;
  final DateTime createdAt;

  RewardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.category,
    required this.imageUrl,
    required this.createdBy,
    required this.createdAt,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      points: json['points'] as int,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? 'superadmin',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points': points,
      'category': category,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  RewardModel copyWith({
    String? id,
    String? name,
    String? description,
    int? points,
    String? category,
    String? imageUrl,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return RewardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool canRedeem(int userPoints) => userPoints >= points;

  String get categoryDisplay => category;

  @override
  String toString() => 'Reward($name - $points pts)';
}
