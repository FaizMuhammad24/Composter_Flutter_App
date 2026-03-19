import '../models/reward_model.dart';

/// 🎁 Reward Service - Aplikasi Monitoring Kompos
/// CRUD Operations + 6 Dummy Rewards
class RewardService {
  static final List<RewardModel> _rewards = [
    RewardModel(
      id: 'r1',
      name: 'Voucher Alfamart',
      description: 'Voucher belanja di Alfamart senilai Rp 25.000',
      points: 500,
      category: 'Voucher',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Alfamart_logo.svg/512px-Alfamart_logo.svg.png',
      createdBy: 'superadmin@kompos.com',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    RewardModel(
      id: 'r2',
      name: 'Voucher Indomaret',
      description: 'Voucher belanja di Indomaret senilai Rp 25.000',
      points: 500,
      category: 'Voucher',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Logo_indomaret.png/512px-Logo_indomaret.png',
      createdBy: 'superadmin@kompos.com',
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
    ),
    RewardModel(
      id: 'r3',
      name: 'Pupuk Kompos 5kg',
      description: 'Pupuk kompos organik premium 5kg untuk tanaman',
      points: 750,
      category: 'Produk',
      imageUrl: 'https://static.wikia.nocookie.net/minecraft/images/8/8b/Compost.png',
      createdBy: 'superadmin@kompos.com',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    RewardModel(
      id: 'r4',
      name: 'Bibit Tanaman Sayur',
      description: 'Paket bibit sayuran segar (tomat, cabai, bayam)',
      points: 300,
      category: 'Produk',
      imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
      createdBy: 'superadmin@kompos.com',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    RewardModel(
      id: 'r5',
      name: 'Tas Belanja Ramah Lingkungan',
      description: 'Tas belanja reusable dari bahan daur ulang',
      points: 200,
      category: 'Merchandise',
      imageUrl: 'https://images.unsplash.com/photo-1591247378418-f7a523e3bf7c?w=400',
      createdBy: 'superadmin@kompos.com',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    RewardModel(
      id: 'r6',
      name: 'Botol Minum Stainless',
      description: 'Botol minum stainless 500ml ramah lingkungan',
      points: 400,
      category: 'Merchandise',
      imageUrl: 'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=400',
      createdBy: 'superadmin@kompos.com',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  // ==================== READ ====================
  static List<RewardModel> getAllRewards() => List.from(_rewards);

  static RewardModel? getRewardById(String id) {
    try {
      return _rewards.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<RewardModel> searchRewards(String query) {
    final q = query.toLowerCase();
    return _rewards.where((r) =>
      r.name.toLowerCase().contains(q) ||
      r.category.toLowerCase().contains(q) ||
      r.description.toLowerCase().contains(q)
    ).toList();
  }

  static List<RewardModel> getRewardsByCategory(String category) =>
    _rewards.where((r) => r.category == category).toList();

  // ==================== CREATE ====================
  static RewardModel createReward({
    required String name,
    required String description,
    required int points,
    required String category,
    required String imageUrl,
    String createdBy = 'superadmin@kompos.com',
  }) {
    final newReward = RewardModel(
      id: 'r${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      points: points,
      category: category,
      imageUrl: imageUrl,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
    _rewards.add(newReward);
    return newReward;
  }

  // ==================== UPDATE ====================
  static bool updateReward(RewardModel updated) {
    final index = _rewards.indexWhere((r) => r.id == updated.id);
    if (index == -1) return false;
    _rewards[index] = updated;
    return true;
  }

  // ==================== DELETE ====================
  static bool deleteReward(String id) {
    final before = _rewards.length;
    _rewards.removeWhere((r) => r.id == id);
    return _rewards.length < before;
  }

  // ==================== STATS ====================
  static int getTotalRewards() => _rewards.length;
  static int getTotalPointsValue() => _rewards.fold(0, (sum, r) => sum + r.points);
  static List<String> getCategories() => _rewards.map((r) => r.category).toSet().toList();
}
