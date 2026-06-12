import '../config/app_constants.dart';

class Validators {
  const Validators._();

  static String? requiredText(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredText(value, fieldName: 'Email');
    if (requiredError != null) {
      return requiredError;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredText(value, fieldName: 'Password');
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.length < AppConstants.minimumPasswordLength) {
      return 'Password must be at least ${AppConstants.minimumPasswordLength} characters';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Value'}) {
    final requiredError = requiredText(value, fieldName: fieldName);
    if (requiredError != null) {
      return requiredError;
    }
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
      return '$fieldName must be greater than zero';
    }
    return null;
  }
}
