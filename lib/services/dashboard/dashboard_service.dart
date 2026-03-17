import '../../models/compost_model.dart';
import '../database/fake_database.dart';

class DashboardService {

  // ==================== TOTAL USERS ====================
  static int getTotalUsers() {
    return FakeDatabase.users.values
        .where((user) => user['role'] == 'user')
        .length;
  }

  // ==================== TOTAL ADMINS ====================
  static int getTotalAdmins() {
    return FakeDatabase.users.values
        .where((user) => user['role'] == 'admin')
        .length;
  }

  // ==================== TOTAL COMPOSTS ====================
  static int getTotalComposts() {
    return FakeDatabase.composts.length;
  }

  // ==================== TOTAL POINTS ====================
  static int getTotalPoints() {

    int total = 0;

    for (var user in FakeDatabase.users.values) {
      if (user['role'] == 'user') {
        total += (user['points'] ?? 0) as int;
      }
    }

    return total;
  }

  // ==================== RECENT TRANSACTIONS ====================
  static List<CompostModel> getRecentTransactions({int limit = 5}) {

    List<CompostModel> composts = FakeDatabase.composts
        .map((c) => CompostModel.fromJson(c))
        .toList();

    composts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return composts.take(limit).toList();
  }
}