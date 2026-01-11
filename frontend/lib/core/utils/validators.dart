/// Validation utilities for form fields

class Validators {
  /// Validate Ethiopian phone number
  /// Accepts formats: +251912345678, 0912345678, 912345678
  static String? validateEthiopianPhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }

    // Remove spaces and dashes
    String phone = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Check for valid Ethiopian phone formats
    // +251 followed by 9 digits
    if (phone.startsWith('+251')) {
      if (phone.length == 13 && RegExp(r'^\+251[79]\d{8}$').hasMatch(phone)) {
        return null;
      }
      return 'Invalid phone. Use format: +251912345678';
    }

    // 0 followed by 9 digits (local format)
    if (phone.startsWith('0')) {
      if (phone.length == 10 && RegExp(r'^0[79]\d{8}$').hasMatch(phone)) {
        return null;
      }
      return 'Invalid phone. Use format: 0912345678';
    }

    // 9 digits starting with 9 or 7
    if (phone.length == 9 && RegExp(r'^[79]\d{8}$').hasMatch(phone)) {
      return null;
    }

    return 'Invalid phone number format';
  }

  /// Validate phone number (required)
  static String? validateRequiredPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    return validateEthiopianPhone(value);
  }

  /// Format phone number to standard format (+251...)
  static String formatPhoneNumber(String phone) {
    // Remove spaces and dashes
    phone = phone.replaceAll(RegExp(r'[\s\-]'), '');

    // Already in international format
    if (phone.startsWith('+251')) {
      return phone;
    }

    // Local format starting with 0
    if (phone.startsWith('0') && phone.length == 10) {
      return '+251${phone.substring(1)}';
    }

    // Just 9 digits
    if (phone.length == 9 && RegExp(r'^[79]\d{8}$').hasMatch(phone)) {
      return '+251$phone';
    }

    return phone;
  }

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name is too short';
    }
    return null;
  }
}
