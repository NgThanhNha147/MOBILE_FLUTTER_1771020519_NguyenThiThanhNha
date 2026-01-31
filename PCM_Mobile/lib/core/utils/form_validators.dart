class FormValidators {
  // Email validation with regex
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  // Password validation with strength check
  static String? validatePassword(String? value, {bool requireStrong = true}) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }

    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }

    if (requireStrong) {
      // Check for uppercase
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Mật khẩu phải có ít nhất 1 chữ hoa';
      }

      // Check for lowercase
      if (!value.contains(RegExp(r'[a-z]'))) {
        return 'Mật khẩu phải có ít nhất 1 chữ thường';
      }

      // Check for number
      if (!value.contains(RegExp(r'[0-9]'))) {
        return 'Mật khẩu phải có ít nhất 1 số';
      }

      // Check for special character
      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
      }
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu';
    }

    if (value != password) {
      return 'Mật khẩu không khớp';
    }

    return null;
  }

  // Full name validation
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ tên';
    }

    if (value.trim().length < 3) {
      return 'Họ tên phải có ít nhất 3 ký tự';
    }

    // Check if contains at least 2 words (first name + last name)
    if (value.trim().split(' ').length < 2) {
      return 'Vui lòng nhập họ và tên đầy đủ';
    }

    return null;
  }

  // Phone number validation (Vietnam format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

    // Vietnam phone number: 10 digits starting with 0
    final phoneRegex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Số điện thoại không hợp lệ';
    }

    return null;
  }

  // Amount validation (for wallet deposit)
  static String? validateAmount(
    String? value, {
    double? minAmount,
    double? maxAmount,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số tiền';
    }

    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      return 'Số tiền không hợp lệ';
    }

    if (minAmount != null && amount < minAmount) {
      return 'Số tiền tối thiểu là ${_formatCurrency(minAmount)}';
    }

    if (maxAmount != null && amount > maxAmount) {
      return 'Số tiền tối đa là ${_formatCurrency(maxAmount)}';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }

  // Min length validation
  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }

    if (value.trim().length < minLength) {
      return '$fieldName phải có ít nhất $minLength ký tự';
    }

    return null;
  }

  // Max length validation
  static String? validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName không được quá $maxLength ký tự';
    }

    return null;
  }

  // Number validation
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName phải là số';
    }

    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'URL không hợp lệ';
    }

    return null;
  }

  // Helper function to format currency
  static String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }

  // Password strength calculator (0-4)
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character variety checks
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    return (strength / 6 * 4).round().clamp(0, 4);
  }

  // Password strength label
  static String getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Rất yếu';
      case 1:
        return 'Yếu';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Mạnh';
      case 4:
        return 'Rất mạnh';
      default:
        return '';
    }
  }
}
