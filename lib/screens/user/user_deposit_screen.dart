import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class UserDepositScreen extends StatefulWidget {
  final String userEmail;
  const UserDepositScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<UserDepositScreen> createState() => _UserDepositScreenState();
}

class _UserDepositScreenState extends State<UserDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _basahController = TextEditingController();
  final _keringController = TextEditingController();
  final _campuranController = TextEditingController();
  
  int _poinDidapat = 0;
  bool _isSubmitting = false;
  bool _isImageUploaded = false; // Simulasi upload foto

  @override
  void dispose() {
    _basahController.dispose();
    _keringController.dispose();
    _campuranController.dispose();
    super.dispose();
  }

  void _calculatePoints() {
    final basah = double.tryParse(_basahController.text) ?? 0;
    final kering = double.tryParse(_keringController.text) ?? 0;
    final campuran = double.tryParse(_campuranController.text) ?? 0;

    setState(() {
      _poinDidapat = ((basah * 10) + (kering * 8) + (campuran * 6)).toInt();
    });
  }

  Future<void> _submitDeposit() async {
    // Validasi Foto
    if (!_isImageUploaded) {
      _showErrorSnackBar('Mohon unggah foto bukti setor sampah terlebih dahulu.');
      return;
    }

    final basah = double.tryParse(_basahController.text) ?? 0;
    final kering = double.tryParse(_keringController.text) ?? 0;
    final campuran = double.tryParse(_campuranController.text) ?? 0;

    if (basah == 0 && kering == 0 && campuran == 0) {
      _showErrorSnackBar('Masukkan setidaknya satu jenis sampah yang disetor.');
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulasi Network Request
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Simulasi: Jika total berat lebih dari 50kg, kita anggap gagal (contoh gagal)
    final totalBerat = basah + kering + campuran;
    if (totalBerat > 50) {
      _showFailureDialog('Gagal Setor Sampah', 'Kapasitas Drop Point penuh atau melebihi batas harian. (Simulasi Gagal)');
    } else {
      _showSuccessDialog();
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
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Berhasil!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sampah berhasil disetorkan. Poin Anda telah ditambahkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '+$_poinDidapat Pts',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange, fontFamily: 'Poppins'),
                  ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifikasi & Riwayat Transaksi diperbarui (Simulasi)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Kembali ke Beranda', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
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
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel, color: Colors.red, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Setor Sampah',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        color: AppColors.primary, // Latar atas agar header menyatu
        child: Column(
          children: [
            // INFO CARD ATAS
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Isi berat (kg) pada jenis sampah yang Anda bawa. Kosongkan jika tidak ada.',
                        style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // BODY KONTEN FORM
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 32, bottom: 40),
                    children: [
                      // TEXT FIELDS INPUT SAMPAH
                      _buildWasteInput(
                        title: 'Organik Basah',
                        subtitle: 'Sisa makanan, sayur, buah',
                        pointsPerKg: 10,
                        controller: _basahController,
                        icon: Icons.eco,
                        iconColor: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildWasteInput(
                        title: 'Organik Kering',
                        subtitle: 'Daun kering, ranting kecil',
                        pointsPerKg: 8,
                        controller: _keringController,
                        icon: Icons.energy_savings_leaf,
                        iconColor: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildWasteInput(
                        title: 'Campuran',
                        subtitle: 'Sampah kebun bercampur',
                        pointsPerKg: 6,
                        controller: _campuranController,
                        icon: Icons.recycling,
                        iconColor: Colors.blue,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // BAGIAN UNGGAH FOTO
                      const Text(
                        'Bukti Foto Penyetoran',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          // Simulasi pilih foto
                          setState(() => _isImageUploaded = !_isImageUploaded);
                        },
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isImageUploaded ? Colors.green : Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _isImageUploaded
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 40),
                                    const SizedBox(height: 8),
                                    const Text('Foto Berhasil Diunggah', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                                    const SizedBox(height: 4),
                                    Text('Tap untuk mengubah foto', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontFamily: 'Poppins')),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt, color: Colors.blue, size: 28),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Tap untuk ambil foto sampah', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                                    const SizedBox(height: 4),
                                    Text('Pastikan foto jelas & terang', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontFamily: 'Poppins')),
                                  ],
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // PREVIEW TOTAL POIN
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Estimasi Poin Didapat', style: TextStyle(color: Colors.black54, fontSize: 13, fontFamily: 'Poppins')),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.orange, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$_poinDidapat Pts',
                                      style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.calculate, color: AppColors.primary, size: 28),
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // TOMBOL SUBMIT
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitDeposit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  'Proses Setor Sampah',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteInput({
    required String title,
    required String subtitle,
    required int pointsPerKg,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          // Info Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Poppins', color: Colors.black87)),
                const SizedBox(height: 2),
                Text('$pointsPerKg Pts / kg • $subtitle', style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Poppins')),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Input Field
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 16),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'kg',
                suffixStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                filled: true,
                fillColor: Colors.grey[50],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (_) => _calculatePoints(),
            ),
          ),
        ],
      ),
    );
  }
}
