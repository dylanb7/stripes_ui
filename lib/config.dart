import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_ui/UI/History/Export/export.dart';

enum AuthStrategy { accessCodeEmail, accessCode }

enum ExportType { menu, profile, perPage }

enum AccountStage { local, invited, enrolled, finished }

enum ProfileType { username, name }

typedef AccountIndicator = Widget? Function(AuthUser user);

typedef AccountAction = Future<bool> Function(
  Map<String, dynamic> userAttributes,
);

typedef ExportAction = Future<void> Function(
  BuildContext context,
  List<Response> responses,
  ExportType type,
);

/// Optional display surfaces. Both are opt-in for embedding applications.
@immutable
class StripesDisplayConfig {
  final bool settingsEnabled;
  final bool insightsEnabled;
  final bool useLegacyNavigation;

  const StripesDisplayConfig({
    this.settingsEnabled = false,
    this.insightsEnabled = false,
    this.useLegacyNavigation = false,
  });
}

/// Independent switches for the in-progress interface.
@immutable
class BetaUiConfig {
  final bool dashboard;
  final bool compactHistory;
  final bool multiSessionFlow;

  /// Collect app terms once per account on this device, before profile setup.
  final bool onboardingTerms;

  /// Shows category illustrations. Color accents can be disabled separately.
  final bool useCategoryTheme;
  final bool useCategoryColors;

  bool get categoryColorsEnabled => useCategoryTheme && useCategoryColors;
  final bool hasGraphing;
  final bool hasSymptomEditing;

  const BetaUiConfig.disabled({
    this.dashboard = false,
    this.compactHistory = false,
    this.multiSessionFlow = false,
    this.onboardingTerms = false,
    this.useCategoryTheme = false,
    this.useCategoryColors = true,
    this.hasGraphing = false,
    this.hasSymptomEditing = false,
  });

  const BetaUiConfig.enabled({
    this.dashboard = true,
    this.compactHistory = true,
    this.multiSessionFlow = true,
    this.onboardingTerms = true,
    this.useCategoryTheme = true,
    this.useCategoryColors = true,
    this.hasGraphing = true,
    this.hasSymptomEditing = true,
  });
}

@immutable
class StripesConfig {
  // Stable app features.
  final bool hasLogging;
  final bool allowsSummaryReport;
  final StripesDisplayConfig display;

  /// Use [BetaUiConfig.enabled] for the full redesign or override individual
  /// switches in [BetaUiConfig.disabled] during testing.
  final BetaUiConfig betaUi;

  // App environment.
  final Locale? locale;
  final Widget Function(BuildContext, Widget?)? builder;
  final List<LocalizationsDelegate>? localizationDelegates;

  // Account and study integration.
  final AuthStrategy? authStrategy;
  final AccountIndicator? stageIndicator;
  final AccountAction? stageAction;
  final Function? onExitStudy;
  final ProfileType? profileType;

  // Export integration.
  final ExportAction? export;
  final List<ExportType>? exportType;

  const StripesConfig({
    required this.profileType,
    required this.hasLogging,
    required this.allowsSummaryReport,
    this.display = const StripesDisplayConfig(),
    this.betaUi = const BetaUiConfig.disabled(),
    this.locale,
    this.authStrategy,
    this.exportType,
    this.export,
    this.stageIndicator,
    this.stageAction,
    this.onExitStudy,
    this.localizationDelegates,
    this.builder,
  });

  const StripesConfig.sandbox({
    this.display = const StripesDisplayConfig(),
    this.betaUi = const BetaUiConfig.disabled(),
  }) : hasLogging = true,
       allowsSummaryReport = true,
       profileType = ProfileType.username,
       export = fileShare,
       builder = null,
       stageAction = null,
       stageIndicator = null,
       authStrategy = null,
       locale = const Locale('en'),
       exportType = null,
       onExitStudy = null,
       localizationDelegates = null;
}
