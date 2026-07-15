class AuthValidators {
  static final RegExp _emailRule = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phoneRule = RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$');
  static final RegExp _passwordRule = RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)[A-Za-z\d\W]{8,256}$');

  static String? requiredField(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? fullName(String? value) {
    final requiredError = requiredField(value, fieldName: 'Full name');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 2) {
      return 'Full name must be at least 2 characters long';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredField(value, fieldName: 'Email');
    if (requiredError != null) return requiredError;
    if (!_emailRule.hasMatch(value!.trim())) {
      return 'Invalid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    final requiredError = requiredField(value, fieldName: 'Phone');
    if (requiredError != null) return requiredError;
    if (!_phoneRule.hasMatch(value!.trim())) {
      return 'Phone number must be a valid Vietnamese phone number';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredField(value, fieldName: 'Password');
    if (requiredError != null) return requiredError;
    if (!_passwordRule.hasMatch(value!.trim())) {
      return 'Password must include at least 1 letter, a number, and at least 8 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final requiredError = requiredField(value, fieldName: 'Confirm password');
    if (requiredError != null) return requiredError;
    if (value!.trim() != password.trim()) {
      return 'Password confirmation does not match';
    }
    return null;
  }
}
