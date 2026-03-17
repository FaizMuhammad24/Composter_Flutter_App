import '../../models/compost_model.dart';
import '../database/fake_database.dart';

class HistoryService {

  // ==================== USER HISTORY ====================
  static Future<List<CompostModel>> getUserHistory(String userEmail) async {

    await Future.delayed(const Duration(milliseconds: 300));

    return FakeDatabase.composts
        .where((compost) => compost['userEmail'] == userEmail)
        .map((compost) => CompostModel.fromJson(compost))
        .toList();
  }

  // ==================== ALL HISTORY (ADMIN) ====================
  static Future<List<CompostModel>> getAllHistory() async {

    await Future.delayed(const Duration(milliseconds: 300));

    return FakeDatabase.composts
        .map((compost) => CompostModel.fromJson(compost))
        .toList();
  }

  // ==================== RECENT TRANSACTIONS ====================
  static Future<List<CompostModel>> getRecentTransactions({int limit = 5}) async {

    await Future.delayed(const Duration(milliseconds: 300));

    List<CompostModel> all = FakeDatabase.composts
        .map((compost) => CompostModel.fromJson(compost))
        .toList();

    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return all.take(limit).toList();
  }
}