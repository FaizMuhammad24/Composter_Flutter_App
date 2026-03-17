/// ✅ Form Validators - Aplikasi Monitoring Kompos
/// Helper functions untuk validasi form input

class Validators {
  Validators._();

  // ==================== EMAIL VALIDATION ====================
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  // ==================== PASSWORD VALIDATION ====================
  /// Validate password (minimum 6 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }

    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }

    if (value != password) {
      return 'Password tidak sama';
    }

    return null;
  }

  // ==================== NAME VALIDATION ====================
  /// Validate name (not empty)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }

    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }

    return null;
  }

  // ==================== NUMBER VALIDATION ====================
  /// Validate number (must be a valid number)
  static String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Angka tidak boleh kosong';
    }

    if (double.tryParse(value) == null) {
      return 'Format angka tidak valid';
    }

    return null;
  }

  /// Validate number with range
  static String? validateNumberRange(String? value, double min, double max, {String? label}) {
    if (value == null || value.isEmpty) {
      return '${label ?? 'Angka'} tidak boleh kosong';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Format angka tidak valid';
    }

    if (number < min || number > max) {
      return '${label ?? 'Angka'} harus antara $min - $max';
    }

    return null;
  }

  // ==================== WEIGHT VALIDATION (for deposit) ====================
  /// Validate deposit weight (0.5 - 50 kg)
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Berat tidak boleh kosong';
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Format berat tidak valid';
    }

    if (weight < 0.5) {
      return 'Berat minimal 0.5 kg';
    }

    if (weight > 50) {
      return 'Berat maksimal 50 kg';
    }

    return null;
  }

  // ==================== POINTS VALIDATION ====================
  /// Validate points (must be positive)
  static String? validatePoints(int? points, int required) {
    if (points == null || points < required) {
      return 'Poin tidak cukup. Dibutuhkan $required poin';
    }

    return null;
  }

  // ==================== GENERAL VALIDATION ====================
  /// Validate required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} tidak boleh kosong';
    }

    return null;
  }

  /// Validate min length
  static String? validateMinLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} tidak boleh kosong';
    }

    if (value.length < minLength) {
      return '${fieldName ?? 'Field'} minimal $minLength karakter';
    }

    return null;
  }

  /// Validate max length
  static String? validateMaxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Field'} maksimal $maxLength karakter';
    }

    return null;
  }
}
