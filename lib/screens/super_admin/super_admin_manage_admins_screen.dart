import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/admin/admin_service.dart';
import '../../services/auth/session_service.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({Key? key}) : super(key: key);
  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isFetching = true;
  bool _showForm = false;

  List<UserModel> _admins = [];
  List<UserModel> _filtered = [];

  UserModel? _currentSuperAdmin;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isFetching = true);
    try {
      _currentSuperAdmin = await SessionService.getCurrentUser();
      _admins = await AdminService.getAllAdmins();
      _filtered = _admins;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat admin: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _admins
          : _admins.where((a) =>
              a.name.toLowerCase().contains(q.toLowerCase()) ||
              a.email.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_currentSuperAdmin == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi tidak valid. Harap login ulang.')));
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await AdminService.createAdminBySuperAdmin(
      superAdminEmail: _currentSuperAdmin!.email,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (result['success']) {
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      
      setState(() {
        _showForm = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
      
      _loadData(); // Reload the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
    
    setState(() => _isLoading = false);
  }

  void _deleteAdmin(int index) {
    final admin = _filtered[index];
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Admin', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text('Yakin hapus "${admin.name}"?', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              if (_currentSuperAdmin == null) return;
              
              setState(() => _isFetching = true);
              final result = await AdminService.deleteAdmin(
                superAdminEmail: _currentSuperAdmin!.email,
                adminUid: admin.uid,
              );
              
              if (!mounted) return;
              
              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message']), backgroundColor: Colors.orange),
                );
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
                );
                setState(() => _isFetching = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.superAdminBg,
      body: Column(
        children: [
          _buildToolbar(),
          if (_showForm) _buildForm(),
          Expanded(
            child: _isFetching 
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                  ? _buildEmpty('Belum ada admin')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _buildAdminCard(i),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: AppColors.superAdminBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${_admins.length} Admin', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              GestureDetector(
                onTap: () => setState(() => _showForm = !_showForm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _showForm ? Colors.grey[300] : AppColors.superAdminPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(_showForm ? Icons.close : Icons.add, color: _showForm ? Colors.black54 : Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(_showForm ? 'Tutup' : 'Tambah', style: TextStyle(color: _showForm ? Colors.black54 : Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Cari admin...',
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

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text('Tambah Admin Baru', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDeco('Nama Admin', Icons.person_outline),
              validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailCtrl,
              decoration: _inputDeco('Email Admin', Icons.email_outlined),
              validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: _inputDeco('Password', Icons.lock_outline),
              validator: (v) => v == null || v.length < 6 ? 'Min 6 karakter' : null,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.superAdminPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Buat Admin', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(int index) {
    final admin = _filtered[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.superAdminPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.superAdminPrimary, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(admin.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14)),
                Text(admin.email, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('● Aktif (Cloud)', style: TextStyle(fontSize: 10, color: Colors.green[700], fontFamily: 'Poppins')),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 22),
            onPressed: () => _deleteAdmin(index),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: Colors.red[100]),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: AppColors.superAdminPrimary),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.superAdminPrimary)),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
  );
}
