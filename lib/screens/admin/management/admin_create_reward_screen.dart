import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../models/reward_model.dart';
import '../../../services/rewards/reward_service.dart';

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
  bool _isLoading = false;
  bool get _isEditMode => widget.existingReward != null;

  // Image state
  File? _pickedFile;
  Uint8List? _pickedBytes;
  String _existingImageUrl = ''; // Untuk edit mode (base64 atau URL lama)

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final r = widget.existingReward!;
      _nameCtrl.text = r.name;
      _descCtrl.text = r.description;
      _categoryCtrl.text = r.category;
      _pointsCtrl.text = r.points.toString();
      _existingImageUrl = r.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  //  Pilih gambar dari Galeri atau Kamera
  // ============================================================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedFile = File(picked.path);
          _pickedBytes = bytes;
          _existingImageUrl = ''; // Clear old image
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: Colors.red[700]),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Gambar',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: Colors.blue[700]),
                ),
                title: const Text('Galeri', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                subtitle: const Text('Pilih dari galeri foto', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.green[700]),
                ),
                title: const Text('Kamera', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                subtitle: const Text('Ambil foto langsung', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_pickedFile != null || _existingImageUrl.isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete_outline, color: Colors.red[700]),
                  ),
                  title: const Text('Hapus Gambar', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  subtitle: const Text('Hapus gambar yang dipilih', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedFile = null;
                      _pickedBytes = null;
                      _existingImageUrl = '';
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  Konversi gambar ke base64 data URI
  // ============================================================
  String _getImageDataUri() {
    if (_pickedBytes != null) {
      final base64Str = base64Encode(_pickedBytes!);
      return 'data:image/jpeg;base64,$base64Str';
    }
    return _existingImageUrl;
  }

  // ============================================================
  //  Simpan
  // ============================================================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final imageUrl = _getImageDataUri();

    if (_isEditMode) {
      final updated = widget.existingReward!.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        points: int.parse(_pointsCtrl.text.trim()),
        imageUrl: imageUrl,
      );
      RewardService.updateReward(updated);
    } else {
      RewardService.createReward(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        points: int.parse(_pointsCtrl.text.trim()),
        imageUrl: imageUrl,
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
                backgroundColor: AppColors.adminPrimary,
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
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
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
              // Image Upload Area
              _buildImageUploadArea(),
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
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.adminPrimary.withValues(alpha: 0.4),
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

  // ============================================================
  //  Widget: Area Upload Gambar (menggantikan kolom URL)
  // ============================================================
  Widget _buildImageUploadArea() {
    final bool hasPickedImage = _pickedBytes != null;
    final bool hasExistingImage = _existingImageUrl.isNotEmpty;
    final bool hasImage = hasPickedImage || hasExistingImage;

    return Center(
      child: GestureDetector(
        onTap: _showImagePickerSheet,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasImage
                  ? AppColors.adminPrimary.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.adminPrimary.withValues(alpha: 0.1),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gambar
                if (hasPickedImage)
                  Image.memory(_pickedBytes!, fit: BoxFit.cover)
                else if (hasExistingImage && _existingImageUrl.startsWith('data:'))
                  Image.memory(
                    base64Decode(_existingImageUrl.split(',').last),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                else if (hasExistingImage)
                  Image.network(
                    _existingImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                else
                  _buildPlaceholder(),

                // Overlay edit icon
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          hasImage ? 'Ganti Foto' : 'Upload Foto',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[400]),
        const SizedBox(height: 4),
        Text('Tambah Foto', style: TextStyle(fontSize: 11, color: Colors.grey[400], fontFamily: 'Poppins')),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
        prefixIcon: Icon(icon, color: AppColors.adminPrimary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.adminPrimary, width: 1.5),
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
