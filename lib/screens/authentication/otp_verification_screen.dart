import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../services/auth/signup_service.dart';
import '../../services/auth/emailjs_service.dart';
import '../admin/admin_main_screen.dart';
import '../user/user_main_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String otpCode;
  final Map<String, dynamic> userData;

  const OtpVerificationScreen({
    Key? key,
    required this.email,
    required this.otpCode,
    required this.userData,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _hiddenController = TextEditingController();
  final List<FocusNode> _focusNodes = [FocusNode()];
  final List<String> _actualValues = List.generate(6, (index) => '');
  final List<bool> _isMasked = List.generate(6, (index) => false);
  bool _isLoading = false;
  String _errorMessage = '';

  // Resend OTP
  late String _currentOtpCode;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _currentOtpCode = widget.otpCode;
    _startCooldown(); // Mulai cooldown saat pertama kali masuk
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _hiddenController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value) {
    // Pastikan hanya angka
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    // Batasi 6 digit
    final limited = digits.length > 6 ? digits.substring(0, 6) : digits;

    // Update hidden controller tanpa trigger onChanged lagi
    if (_hiddenController.text != limited) {
      _hiddenController.text = limited;
      _hiddenController.selection = TextSelection.fromPosition(
        TextPosition(offset: limited.length),
      );
    }

    final prevLength = _actualValues.where((v) => v.isNotEmpty).length;

    setState(() {
      for (int i = 0; i < 6; i++) {
        if (i < limited.length) {
          final isNewDigit = i >= prevLength;
          _actualValues[i] = limited[i];
          // Mask angka sebelumnya saat mengetik yang baru
          if (!isNewDigit) {
            _isMasked[i] = true;
          } else {
            _isMasked[i] = false; // Angka baru tampil dulu
            // Jadwalkan mask setelah 600ms
            final capturedIndex = i;
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted && _actualValues[capturedIndex].isNotEmpty) {
                setState(() => _isMasked[capturedIndex] = true);
              }
            });
          }
        } else {
          _actualValues[i] = '';
          _isMasked[i] = false;
        }
      }
    });

    // Auto verifikasi saat 6 digit sudah masuk
    if (limited.length == 6) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) _verifyOtp();
      });
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    // Generate kode OTP baru
    String newOtp = (100000 + Random().nextInt(900000)).toString();
    bool sent = await EmailJSService.sendOtpEmail(widget.email, newOtp);

    if (mounted) {
      if (sent) {
        setState(() {
          _currentOtpCode = newOtp;
          _isResending = false;
          _hiddenController.clear();
          for (int i = 0; i < 6; i++) {
            _actualValues[i] = '';
            _isMasked[i] = false;
          }
        });
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kode OTP baru telah dikirim!', style: TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() {
          _isResending = false;
          _errorMessage = 'Gagal mengirim ulang kode OTP. Coba lagi nanti.';
        });
      }
    }
  }

  void _verifyOtp() async {
    String enteredOtp = _actualValues.join();
    if (enteredOtp.length != 6) {
      setState(() => _errorMessage = 'Masukkan 6 digit kode OTP');
      return;
    }

    if (enteredOtp == _currentOtpCode) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Proses signup ke Firebase
      final result = await SignupService.finalizeSignup(widget.userData);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          final user = result['user'];
          // Langsung navigasi ke Home sesuai role, bukan ke Login
          Widget homeScreen;
          if (user.role == 'admin' || user.role == 'super_admin') {
            homeScreen = const AdminMainScreen();
          } else {
            homeScreen = UserMainScreen(user: user);
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => homeScreen),
            (route) => false,
          );
        } else {
          setState(() => _errorMessage = result['message']);
        }
      }
    } else {
      setState(() => _errorMessage = 'Kode OTP salah. Silakan coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verifikasi Email', style: TextStyle(fontFamily: 'Poppins', color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Masukkan Kode OTP',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Kode OTP telah dikirim ke email:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 4),
              // Email visible dan bisa di-select
              SelectableText(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 40),
              // Kotak tampilan OTP kustom
              GestureDetector(
                onTap: () => _focusNodes[0].requestFocus(),
                child: Stack(
                  children: [
                    // TextField tersembunyi sebagai penangkap input
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        width: 1,
                        child: TextField(
                          controller: _hiddenController,
                          focusNode: _focusNodes[0],
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autofocus: true,
                          onChanged: _onOtpChanged,
                        ),
                      ),
                    ),
                    // Kotak tampilan kustom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        final bool hasValue = index < _actualValues.where((v) => v.isNotEmpty).length;
                        final bool isCurrent = index == _actualValues.where((v) => v.isNotEmpty).length;
                        final bool isMasked = index < _isMasked.length && _isMasked[index];
                        final String displayValue = hasValue
                            ? (isMasked ? '●' : _actualValues[index])
                            : '';

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 45,
                          height: 55,
                          decoration: BoxDecoration(
                            color: hasValue ? Colors.grey.shade100 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasValue
                                  ? AppColors.primary
                                  : isCurrent
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                              width: (hasValue || isCurrent) ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: displayValue.isEmpty && isCurrent
                              ? Container(
                                  width: 2,
                                  height: 24,
                                  color: AppColors.primary,
                                )
                              : Text(
                                  displayValue,
                                  style: TextStyle(
                                    fontSize: isMasked ? 20 : 22,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    color: Colors.black87,
                                  ),
                                ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14, fontFamily: 'Poppins'),
                ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _verifyOtp,
                        child: const Text('Verifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      ),
                    ),
              const SizedBox(height: 20),
              // Tombol Kirim Ulang Kode
              _isResending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Tidak menerima kode? ',
                          style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Poppins'),
                        ),
                        GestureDetector(
                          onTap: _resendCooldown > 0 ? null : _resendOtp,
                          child: Text(
                            _resendCooldown > 0
                                ? 'Kirim ulang (${_resendCooldown}s)'
                                : 'Kirim Ulang Kode',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: _resendCooldown > 0 ? Colors.grey : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
