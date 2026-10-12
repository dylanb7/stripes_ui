import 'package:equatable/equatable.dart';

/// Profile information kept on this device until backend support is added.
class ProfileCondition extends Equatable {
  final String selection;
  final String details;

  const ProfileCondition(this.selection, {this.details = ''});

  static const choices = [
    'Angelman syndrome',
    'Fragile X syndrome',
    'GRIN1 gene disorder',
    'GRIN2A gene disorder',
    'GRIN2B gene disorder',
    'Other',
    'Not Sure',
  ];

  String get label => selection == 'Other' && details.isNotEmpty
      ? 'Other: $details'
      : selection;

  factory ProfileCondition.fromJson(Map<String, dynamic> json) =>
      ProfileCondition(
        json['selection'] as String,
        details: json['details'] as String? ?? '',
      );

  Map<String, String> toJson() => {
    'selection': selection,
    if (selection == 'Other') 'details': details,
  };

  @override
  List<Object?> get props => [selection, details];
}
