import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String dateToMDY(DateTime dateTime, BuildContext context) {
  final String local = Localizations.localeOf(context).languageCode;
  return DateFormat.yMd(local).format(dateTime);
}

String timeString(DateTime dateTime, BuildContext context) {
  final String local = Localizations.localeOf(context).languageCode;
  return DateFormat.jm(local).format(dateTime);
}
