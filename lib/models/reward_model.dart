class RewardModel {
  final String id;
  final String name;
  final String description;
  final int points;
  final int stock;
  final String imageUrl; // URL or local asset path
  final String category;
  final bool isActive;
  final DateTime createdAt;

  RewardModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.points,
    this.stock = 0,
    required this.imageUrl,
    this.category = 'Umum',
    this.isActive = true,
    required this.createdAt,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
      stock: json['stock'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? 'Umum',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points': points,
      'stock': stock,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  RewardModel copyWith({
    String? id,
    String? name,
    String? description,
    int? points,
    int? stock,
    String? imageUrl,
    String? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RewardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool canRedeem(int userPoints) => userPoints >= points;
}
