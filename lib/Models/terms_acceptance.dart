/// A device-local record of app terms acceptance, separate from study consent.
class TermsAcceptance {
  final String version;
  final DateTime acceptedAt;

  const TermsAcceptance({required this.version, required this.acceptedAt});

  factory TermsAcceptance.fromJson(Map<String, dynamic> json) =>
      TermsAcceptance(
        version: json['version'] as String,
        acceptedAt: DateTime.parse(json['acceptedAt'] as String).toUtc(),
      );

  Map<String, dynamic> toJson() => {
    'version': version,
    'acceptedAt': acceptedAt.toUtc().toIso8601String(),
  };
}
