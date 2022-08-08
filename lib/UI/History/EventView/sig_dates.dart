DateTime today() {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime getMinDate() {
  final DateTime def = DateTime.now().subtract(
    const Duration(days: 365),
  );
  return def;
}
