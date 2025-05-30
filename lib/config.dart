import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_ui/UI/History/EventView/export.dart';

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

enum ProfileType { username, name }

typedef AccountIndicator = Widget? Function(AuthUser user);

typedef AccountAction = Future<bool> Function(
    Map<String, dynamic> userAttributes);

typedef ExportAction = Future<void> Function(
    BuildContext context, List<Response> responses, ExportType type);

@immutable
class StripesConfig {
  final bool hasGraphing, hasLogging, hasSymptomEditing;

  final ExportAction? export;

  final List<ExportType>? exportType;

  final Locale? locale;

  final AuthStrategy? authStrategy;

  final AccountIndicator? stageIndicator;

  final AccountAction? stageAction;

  final Function? onExitStudy;

  final ProfileType? profileType;

  final Widget Function(BuildContext, Widget?)? builder;

  const StripesConfig(
      {required this.profileType,
      required this.hasGraphing,
      required this.hasLogging,
      this.hasSymptomEditing = true,
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
        hasSymptomEditing = true,
        profileType = ProfileType.username,
        export = fileShare,
        builder = null,
        stageAction = null,
        stageIndicator = null,
        authStrategy = null,
        locale = const Locale('en'),
        exportType = null,
        onExitStudy = null;
}
