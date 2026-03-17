/// 🎁 Reward Model - Aplikasi Monitoring Kompos
/// Model untuk katalog reward yang bisa ditukar dengan poin

class RewardModel {
  final String id;
  final String name;
  final String description;
  final int points;
  final int stock;
  final String category; // voucher, produk, merchandise
  final String? image;

  RewardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.stock,
    required this.category,
    this.image,
  });

  // ==================== FROM JSON ====================
  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      points: json['points'] as int,
      stock: json['stock'] as int,
      category: json['category'] as String,
      image: json['image'] as String?,
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points': points,
      'stock': stock,
      'category': category,
      'image': image,
    };
  }

  // ==================== COPY WITH ====================
  RewardModel copyWith({
    String? id,
    String? name,
    String? description,
    int? points,
    int? stock,
    String? category,
    String? image,
  }) {
    return RewardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      image: image ?? this.image,
    );
  }

  // ==================== HELPERS ====================
  /// Check if reward is available
  bool get isAvailable => stock > 0;

  /// Check if user can redeem (has enough points)
  bool canRedeem(int userPoints) => userPoints >= points && isAvailable;

  /// Get category display name
  String get categoryDisplay {
    switch (category.toLowerCase()) {
      case 'voucher':
        return 'Voucher';
      case 'produk':
        return 'Produk';
      case 'merchandise':
        return 'Merchandise';
      default:
        return category;
    }
  }

  @override
  String toString() {
    return 'Reward($name - $points pts, stock: $stock)';
  }
}
