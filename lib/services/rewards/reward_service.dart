import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reward_model.dart';

class RewardService {
  static final CollectionReference _rewardsCol = 
      FirebaseFirestore.instance.collection('rewards');

  /// Ambil semua reward yang aktif
  static Future<List<RewardModel>> getAllRewards() async {
    try {
      final snap = await _rewardsCol
          .where('isActive', isEqualTo: true)
          .orderBy('points', descending: false)
          .get();
      return snap.docs
          .map((doc) => RewardModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error mengambi rewards: $e');
      return [];
    }
  }

  /// Ambil beberapa reward terpopuler untuk halaman depan
  static Future<List<RewardModel>> getPopularRewards({int limit = 4}) async {
    try {
      final snap = await _rewardsCol
          .where('isActive', isEqualTo: true)
          .orderBy('points', descending: false) // Untuk sementara urut berdasarkan poin termurah
          .limit(limit)
          .get();
      return snap.docs
          .map((doc) => RewardModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error mengambil popular rewards: $e');
      return [];
    }
  }

  /// Khusus untuk development: Inject initial data biar gak kosong
  static Future<void> seedInitialData() async {
    final existing = await _rewardsCol.limit(1).get();
    if (existing.docs.isEmpty) {
      final initialRewards = [
        RewardModel(
          id: _rewardsCol.doc().id,
          name: 'Voucher\nAlfamart',
          description: 'Voucher Alfamart Rp50.000',
          points: 500,
          stock: 100,
          imageUrl: 'assets/images/voucher.png',
          category: 'Voucher',
          createdAt: DateTime.now(),
        ),
        RewardModel(
          id: _rewardsCol.doc().id,
          name: 'Pupuk\nOrganik',
          description: 'Pupuk Organik Cair 1L',
          points: 300,
          stock: 50,
          imageUrl: 'assets/images/fertilizer.png',
          category: 'Produk',
          createdAt: DateTime.now(),
        ),
        RewardModel(
          id: _rewardsCol.doc().id,
          name: 'Bibit\nTanaman',
          description: 'Bibit Sayuran Mix',
          points: 200,
          stock: 200,
          imageUrl: 'assets/images/seed.png',
          category: 'Produk',
          createdAt: DateTime.now(),
        ),
        RewardModel(
          id: _rewardsCol.doc().id,
          name: 'Tas\nBelanja',
          description: 'Tas Belanja Ramah Lingkungan',
          points: 150,
          stock: 20,
          imageUrl: 'assets/images/tote.png',
          category: 'Merchandise',
          createdAt: DateTime.now(),
        ),
      ];

      for (var reward in initialRewards) {
        await _rewardsCol.doc(reward.id).set(reward.toJson());
      }
    }
  }

  static Future<void> createReward({
    required String name,
    required String description,
    required String category,
    required int points,
    required String imageUrl,
  }) async {
    final id = _rewardsCol.doc().id;
    final reward = RewardModel(
      id: id,
      name: name,
      description: description,
      category: category,
      points: points,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
    await _rewardsCol.doc(id).set(reward.toJson());
  }

  static Future<void> updateReward(RewardModel reward) async {
    await _rewardsCol.doc(reward.id).update(reward.toJson());
  }

  static Future<void> deleteReward(String id) async {
    await _rewardsCol.doc(id).delete();
  }

  static Future<int> getTotalRewards() async {
    final snap = await _rewardsCol.count().get();
    return snap.count ?? 0;
  }

  static Future<int> getTotalPointsValue() async {
    final snap = await _rewardsCol.get();
    int total = 0;
    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('points')) {
        total += (data['points'] as num).toInt();
      }
    }
    return total;
  }

  static List<String> getCategories() {
    return ['Voucher', 'Produk', 'Merchandise'];
  }
}
