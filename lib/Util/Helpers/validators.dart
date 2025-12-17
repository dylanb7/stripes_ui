String? emailDigest(String? val) {
  if (val == null || val.isEmpty) {
    return 'Empty Field';
  }
  final emailReg = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  if (emailReg.hasMatch(val)) {
    return null;
  }
  return 'Invalid Email';
}

String? customPassDigest(String? val) {
  if (val == null || val.isEmpty) {
    return 'Empty Field';
  }
  if (val.length < 8) {
    return "Password must be at least 8 characters\n";
  }
  if (!RegExp("(?=.*[A-Z])").hasMatch(val)) {
    return "Password must contain at least one uppercase letter\n";
  }
  if (!RegExp("(?=.*[a-z])").hasMatch(val)) {
    return "Password must contain at least one lowercase letter\n";
  }
  if (!RegExp((r'\d')).hasMatch(val)) {
    return "Password must contain at least one number\n";
  }
  return null;
}

String? nameValidator(String? name) {
  if (name == null || name.isEmpty) return 'Empty Field';
  if (name.contains(' ')) return 'Name cannot have a space';
  return null;
}
