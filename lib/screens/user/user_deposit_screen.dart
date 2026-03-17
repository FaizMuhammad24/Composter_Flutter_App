import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/app_radius.dart';
import '../../utils/validators.dart';
import '../../services/compost/compost_service.dart';

class UserDepositScreen extends StatefulWidget {
  final String userEmail;
  const UserDepositScreen({Key? key, required this.userEmail}) : super(key: key);
  @override
  State<UserDepositScreen> createState() => _UserDepositScreenState();
}

class _UserDepositScreenState extends State<UserDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  String _jenisSampah = 'Organik Basah';
  final _beratController = TextEditingController();
  String _lokasi = 'Drop Point 1 (Jl. Kompos No. 1)';
  int _poinDidapat = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _beratController.dispose();
    super.dispose();
  }

  // Calculate points based on waste type and weight
  void _calculatePoints() {
    final berat = double.tryParse(_beratController.text) ?? 0;
    setState(() {
      switch (_jenisSampah) {
        case 'Organik Basah':
          _poinDidapat = (berat * 10).toInt();
          break;
        case 'Organik Kering':
          _poinDidapat = (berat * 8).toInt();
          break;
        case 'Campuran':
          _poinDidapat = (berat * 6).toInt();
          break;
        default:
          _poinDidapat = 0;
      }
    });
  }

  // Submit deposit
  Future<void> _submitDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final berat = double.parse(_beratController.text);
      
      final result = await CompostService.addCompost(
        userEmail: widget.userEmail,
        wasteType: _jenisSampah,
        weight: berat,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: AppRadius.shapeMd,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            const SizedBox(width: AppSpacing.sm),
            const Text('Berhasil!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Penyetoran sampah berhasil!'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Column(
                children: [
                  Icon(Icons.star, color: AppColors.success, size: 48),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '+$_poinDidapat Poin',
                    style: AppTextStyles.h2.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close deposit screen
            },
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Reset form
              setState(() {
                _beratController.clear();
                _poinDidapat = 0;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Setor Lagi'),
          ),
        ],
      ),
    );
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Setor Sampah'),
        backgroundColor: AppColors.user,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: AppColors.primary.withOpacity(0.1),
                shape: AppRadius.shapeMd,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Konversi Poin:\n1 kg Organik Basah = 10 poin\n1 kg Organik Kering = 8 poin\n1 kg Campuran = 6 poin',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Jenis Sampah
              DropdownButtonFormField<String>(
                value: _jenisSampah,
                decoration: InputDecoration(
                  labelText: 'Jenis Sampah',
                  prefixIcon: const Icon(Icons.delete_outline),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                ),
                items: ['Organik Basah', 'Organik Kering', 'Campuran']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _jenisSampah = v!);
                  _calculatePoints();
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Berat
              TextFormField(
                controller: _beratController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Berat (kg)',
                  prefixIcon: const Icon(Icons.scale),
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                ),
                validator: Validators.validateWeight,
                onChanged: (_) => _calculatePoints(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Lokasi
              DropdownButtonFormField<String>(
                value: _lokasi,
                decoration: InputDecoration(
                  labelText: 'Lokasi Drop Point',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                ),
                items: [
                  'Drop Point 1 (Jl. Kompos No. 1)',
                  'Drop Point 2 (Jl. Hijau No. 5)',
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _lokasi = v!),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Preview Poin
              Card(
                color: AppColors.success.withOpacity(0.1),
                shape: AppRadius.shapeMd,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        'Poin yang Didapat',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: AppColors.success, size: 32),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '$_poinDidapat',
                            style: AppTextStyles.h1.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDeposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Konfirmasi Setor',
                        style: AppTextStyles.buttonMedium,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
