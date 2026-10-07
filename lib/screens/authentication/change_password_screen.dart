import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String? username;
  const ChangePasswordScreen({Key? key, this.username}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Tidak ada pengguna yang sedang login.");
      
      // Re-authenticate user first using their pseudo-email
      final email = '${_usernameController.text.trim()}@icompost.app';
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: _oldPasswordController.text,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(_newPasswordController.text);
      
      if (!mounted) return;
      
      // Show success dialog
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
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
              ),
              const SizedBox(height: 24),
              const Text('Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              const Text(
                'Kata sandi Anda telah berhasil diubah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontFamily: 'Poppins', fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup Dialog
                    Navigator.pop(context); // Kembali ke Profile
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      );
      
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan saat mengubah kata sandi.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Kata sandi sekarang yang Anda masukkan salah.';
      } else if (e.code == 'weak-password') {
        message = 'Kata sandi baru terlalu lemah (minimal 6 karakter).';
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ubah Password', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: BackButton(color: Colors.white.withValues(alpha: 0.9)),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Amankan Akun Anda',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Silakan masukkan kata sandi lama Anda untuk memverifikasi, lalu buat kata sandi yang baru.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: 'Poppins', height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        _buildTextField(
                          controller: _usernameController,
                          hint: 'Username',
                          icon: Icons.person_outline,
                          obscureText: false,
                          enabled: false, // Read only di profile
                          validator: (value) => (value == null || value.isEmpty) ? 'Username tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _oldPasswordController,
                          hint: 'Password Sekarang',
                          icon: Icons.lock_outline,
                          obscureText: _obscureOld,
                          onVisibilityToggle: () => setState(() => _obscureOld = !_obscureOld),
                          validator: (value) => (value == null || value.isEmpty) ? 'Password sekarang tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _newPasswordController,
                          hint: 'Password Baru',
                          icon: Icons.lock_reset,
                          obscureText: _obscureNew,
                          onVisibilityToggle: () => setState(() => _obscureNew = !_obscureNew),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password baru tidak boleh kosong';
                            if (value.length < 6) return 'Password minimal 6 karakter';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: 'Konfirmasi Password Baru',
                          icon: Icons.check_circle_outline,
                          obscureText: _obscureConfirm,
                          onVisibilityToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                            if (value != _newPasswordController.text) return 'Password tidak cocok (gagal)';
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleChangePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'Ubah Password',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscureText,
    bool enabled = true,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        enabled: enabled,
        style: TextStyle(fontSize: 15, fontFamily: 'Poppins', color: enabled ? Colors.black : Colors.grey[600]),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, fontFamily: 'Poppins'),
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 21),
          suffixIcon: onVisibilityToggle != null 
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey[400],
                  size: 21,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }
}
