import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../services/compost/compost_service.dart';
import '../../services/database/storage_service.dart';

class UserDepositScreen extends StatefulWidget {
  final String userEmail;
  const UserDepositScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<UserDepositScreen> createState() => _UserDepositScreenState();
}

class _UserDepositScreenState extends State<UserDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  File? _selectedImage;
  int _poinDidapat = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculatePoints(String value) {
    final weight = double.tryParse(value) ?? 0;
    setState(() {
      _poinDidapat = (weight * 10).toInt();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Kompresi agar hemat storage
        maxWidth: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil gambar: $e');
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Kamera', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Galeri', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDeposit() async {
    if (_weightController.text.isEmpty || (double.tryParse(_weightController.text) ?? 0) <= 0) {
      _showErrorSnackBar('Masukkan berat sampah yang valid.');
      return;
    }

    if (_selectedImage == null) {
      _showErrorSnackBar('Mohon ambil foto bukti setor sampah.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload ke Firebase Storage
      final imageUrl = await _storageService.uploadCompostPhoto(
        userEmail: widget.userEmail,
        imageFile: _selectedImage!,
      );

      if (imageUrl == null) {
        throw Exception('Gagal mengunggah foto ke storage.');
      }

      // 2. Simpan ke Firestore
      final result = await CompostService.addCompost(
        userEmail: widget.userEmail,
        weight: double.parse(_weightController.text),
        imageUrl: imageUrl,
      );

      if (result['success']) {
        _showSuccessDialog();
      } else {
        _showFailureDialog('Gagal', result['message'] ?? 'Terjadi kesalahan sistem.');
      }
    } catch (e) {
      _showFailureDialog('Kesalahan', e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 24),
            const Text('Berhasil!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            const Text('Sampah berhasil disetorkan. Poin Anda telah ditambahkan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  Text('+$_poinDidapat Pts', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange, fontFamily: 'Poppins')),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.pop(context); // Kembali ke Dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailureDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins')),
            const SizedBox(height: 24),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'Poppins')), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setor Sampah', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              color: AppColors.primary,
              child: const Column(
                children: [
                  Icon(Icons.recycling, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Ubah Sampah Jadi Berkah!',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SOP SECTION
                    const Text('SOP Setor Sampah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    const SizedBox(height: 12),
                    _buildSopStep(1, 'Pilah: Pastikan hanya sampah organik.', Icons.check_circle_outline),
                    _buildSopStep(2, 'Timbang: Masukkan berat sampah (kg).', Icons.scale_outlined),
                    _buildSopStep(3, 'Masukkan: Masukkan sampah ke corong.', Icons.input_rounded),
                    _buildSopStep(4, 'Foto: Ambil foto sebagai bukti menggunakan timestamp.', Icons.camera_alt_outlined),
                    
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

                    // INPUT SECTON
                    const Text('Input Berat Sampah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        suffixText: 'kg',
                        prefixIcon: const Icon(Icons.monitor_weight_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      ),
                      onChanged: _calculatePoints,
                    ),
                    const SizedBox(height: 8),
                    Text('1 kg = 10 Pts', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Poppins')),

                    const SizedBox(height: 32),

                    // PHOTO SECTION
                    const Text('Foto Bukti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _showPickerOptions,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _selectedImage != null ? Colors.green : Colors.grey[300]!, width: 2),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('Ambil Foto / Pilih Galeri', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // SUMMARY & SUBMIT
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estimasi Poin', style: TextStyle(color: Colors.black54, fontSize: 13, fontFamily: 'Poppins')),
                              Text('$_poinDidapat Pts', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange, fontFamily: 'Poppins')),
                            ],
                          ),
                          const Icon(Icons.stars, color: Colors.orange, size: 40),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitDeposit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('SETOR SEKARANG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSopStep(int number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Text(number.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13))),
        ],
      ),
    );
  }
}
