enum DetailLayoutPreference { automatic, stacked }

/// Display choices stored on this device and shared across profiles.
class AppDisplaySettings {
  final DetailLayoutPreference detailLayout;

  const AppDisplaySettings({
    this.detailLayout = DetailLayoutPreference.automatic,
  });

  AppDisplaySettings copyWith({DetailLayoutPreference? detailLayout}) =>
      AppDisplaySettings(detailLayout: detailLayout ?? this.detailLayout);
}
