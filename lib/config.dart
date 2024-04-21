import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';

enum AuthStrategy {
  accessCodeEmail,
  accessCode;
}

enum ExportType {
  menu,
  profile,
  perPage;
}

enum AccountStage { local, invited, enrolled, finished }

typedef AccountIndicator = Widget Function(Map<String, dynamic> userAttributes);

typedef AccountAction = Future<bool> Function(
    Map<String, dynamic> userAttributes);

typedef ExportAction = Future<void> Function(List<Response> responses);

@immutable
class StripesConfig {
  final bool hasGraphing, hasLogging;

  final ExportAction? export;

  final ExportType? exportType;

  final Locale? locale;

  final AuthStrategy? authStrategy;

  final AccountIndicator? stageIndicator;

  final AccountAction? stageAction;

  final Function? onExitStudy;

  final Widget Function(BuildContext, Widget?)? builder;

  const StripesConfig(
      {required this.hasGraphing,
      required this.hasLogging,
      this.locale,
      this.authStrategy,
      this.exportType,
      this.export,
      this.stageIndicator,
      this.stageAction,
      this.onExitStudy,
      this.builder});

  const StripesConfig.sandbox()
      : hasGraphing = true,
        hasLogging = true,
        export = null,
        builder = null,
        stageAction = null,
        stageIndicator = null,
        authStrategy = null,
        locale = const Locale('en'),
        exportType = null,
        onExitStudy = null;
}
