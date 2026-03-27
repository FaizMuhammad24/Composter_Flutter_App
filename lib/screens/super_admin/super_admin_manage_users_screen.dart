import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/user/user_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchCtrl = TextEditingController();
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isFetching = true);
    try {
      final users = await UserService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _filtered = users;
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users
              .where((u) =>
                  u.name.toLowerCase().contains(q.toLowerCase()) ||
                  u.email.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  void _deleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus User', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text('Yakin hapus "${user.name}"?\nEmail: ${user.email}', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isFetching = true);
              final result = await UserService.deleteUser(user.uid);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result['message']),
                backgroundColor: result['success'] ? Colors.orange : Colors.red,
              ));
              _loadUsers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = _users.fold<int>(0, (sum, u) => sum + (u.points ?? 0));

    return Column(
      children: [
        _buildToolbar(totalPoints),
        Expanded(
          child: _isFetching
              ? const Center(child: CircularProgressIndicator(color: AppColors.superAdminPrimary))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.blue[100]),
                          const SizedBox(height: 12),
                          const Text('Tidak ada user ditemukan', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      color: AppColors.superAdminPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildUserCard(_filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildToolbar(int totalPoints) {
    return Container(
      color: AppColors.superAdminBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              _buildMiniStat('Total User', '${_users.length}', Colors.blue, Icons.people_outline),
              const SizedBox(width: 8),
              _buildMiniStat('Total Poin', '$totalPoints', Colors.amber[700]!, Icons.stars),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Cari user...',
              hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins')),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Poppins')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final shortUid = user.uid.length >= 8 ? user.uid.substring(0, 8).toUpperCase() : user.uid.toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[50],
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14)),
                Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins')),
                const SizedBox(height: 2),
                Text('ID: $shortUid', style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontFamily: 'Poppins')),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${user.points ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
            onPressed: () => _deleteUser(user),
          ),
        ],
      ),
    );
  }
}
