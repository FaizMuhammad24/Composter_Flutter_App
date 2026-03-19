import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/reward_model.dart';
import '../../services/reward_service.dart';

class CreateRewardScreen extends StatefulWidget {
  final RewardModel? existingReward;
  const CreateRewardScreen({Key? key, this.existingReward}) : super(key: key);

  @override
  State<CreateRewardScreen> createState() => _CreateRewardScreenState();
}

class _CreateRewardScreenState extends State<CreateRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  bool _isLoading = false;
  bool get _isEditMode => widget.existingReward != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final r = widget.existingReward!;
      _nameCtrl.text = r.name;
      _descCtrl.text = r.description;
      _categoryCtrl.text = r.category;
      _pointsCtrl.text = r.points.toString();
      _imageCtrl.text = r.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _pointsCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (_isEditMode) {
      final updated = widget.existingReward!.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        points: int.parse(_pointsCtrl.text.trim()),
        imageUrl: _imageCtrl.text.trim(),
      );
      RewardService.updateReward(updated);
    } else {
      RewardService.createReward(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        points: int.parse(_pointsCtrl.text.trim()),
        imageUrl: _imageCtrl.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditMode ? 'Reward Diperbarui!' : 'Reward Ditambahkan!',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _isEditMode ? 'Data reward berhasil diperbarui.' : 'Reward baru berhasil ditambahkan.',
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.superAdminPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Selesai', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.superAdminBg,
      appBar: AppBar(
        backgroundColor: AppColors.superAdminPrimary,
        title: Text(
          _isEditMode ? 'Edit Reward' : 'Tambah Reward',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview
              _buildImagePreview(),
              const SizedBox(height: 20),
              _buildCard([
                _buildLabel('Nama Reward'),
                _buildField(
                  controller: _nameCtrl,
                  hint: 'Contoh: Voucher Alfamart',
                  icon: Icons.card_giftcard_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Deskripsi'),
                _buildField(
                  controller: _descCtrl,
                  hint: 'Deskripsikan reward ini...',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                ),
              ]),
              const SizedBox(height: 16),
              _buildCard([
                _buildLabel('Kategori'),
                _buildField(
                  controller: _categoryCtrl,
                  hint: 'Contoh: Voucher, Produk, Merchandise',
                  icon: Icons.category_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Kategori tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Poin yang Dibutuhkan'),
                _buildField(
                  controller: _pointsCtrl,
                  hint: 'Contoh: 500',
                  icon: Icons.stars_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Poin tidak boleh kosong';
                    if (int.tryParse(v) == null) return 'Masukkan angka yang valid';
                    if (int.parse(v) <= 0) return 'Poin harus lebih dari 0';
                    return null;
                  },
                ),
              ]),
              const SizedBox(height: 16),
              _buildCard([
                _buildLabel('URL Gambar'),
                _buildField(
                  controller: _imageCtrl,
                  hint: 'https://example.com/image.jpg',
                  icon: Icons.image_outlined,
                  onChanged: (_) => setState(() {}),
                ),
              ]),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.superAdminPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.superAdminPrimary.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isEditMode ? 'Perbarui Reward' : 'Simpan Reward',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final url = _imageCtrl.text.trim();
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.superAdminPrimary.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: AppColors.superAdminPrimary.withOpacity(0.1), blurRadius: 12)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 4),
                    Text('Preview', style: TextStyle(fontSize: 11, color: Colors.grey[400], fontFamily: 'Poppins')),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.superAdminPrimary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.superAdminPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
