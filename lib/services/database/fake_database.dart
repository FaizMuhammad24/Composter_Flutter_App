import '../auth/password_service.dart';

class FakeDatabase {

  // Initialize dengan demo accounts
  static Map<String, Map<String, dynamic>> users = {
    // Super Admin
    'superadmin@kompos.com': {
      'uid': 'superadmin_001',
      'name': 'Super Admin',
      'email': 'superadmin@kompos.com',
      'password': PasswordService.hashPassword('superadmin123'),
      'role': 'super_admin',
      'created_at': '2026-01-01T00:00:00',
    },
    // Admin
    'admin@kompos.com': {
      'uid': 'admin_001',
      'name': 'Admin Kompos',
      'email': 'admin@kompos.com',
      'password': PasswordService.hashPassword('admin123'),
      'role': 'admin',
      'created_at': '2026-01-01T00:00:00',
      'created_by': 'superadmin_001',
    },
    // User
    'user@kompos.com': {
      'uid': 'user_001',
      'name': 'Budi Santoso',
      'email': 'user@kompos.com',
      'password': PasswordService.hashPassword('user123'),
      'role': 'user',
      'points': 450,
      'created_at': '2026-01-01T00:00:00',
    },
  };

  static List<Map<String, dynamic>> composts = [];

  static List<Map<String, dynamic>> transactions = [];

}