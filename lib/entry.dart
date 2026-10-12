// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/Navigation/route_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Questions/question_ui_registry.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Util/Design/custom_themes.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/config.dart';

import 'l10n/app_localizations.dart';

final class Logger extends ProviderObserver {
  const Logger();
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    print('''
{
  "provider": "${context.provider.name ?? context.provider.runtimeType}",
  "newValue": "$newValue"
}''');
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    print('added provider ${context.provider.runtimeType}');
    super.didAddProvider(context, value);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    print('removed provider ${context.provider.runtimeType}');
    super.didDisposeProvider(context);
  }
}

/// Global key for ScaffoldMessenger to show snackbars that persist across navigation
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class StripesApp extends StatelessWidget {
  final StripesRepoPackage? repos;

  final StripesConfig config;

  final QuestionUIRegistry? questionUIRegistry;

  const StripesApp(
      {this.repos,
      this.config = const StripesConfig.sandbox(),
      this.questionUIRegistry,
      super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        configProvider.overrideWith((ref) => config),
        if (repos != null) reposProvider.overrideWith((ref) => repos!),
        if (questionUIRegistry != null)
          questionUIRegistryProvider.overrideWith((ref) => questionUIRegistry!),
      ],
      observers: [if (config.hasLogging) const Logger()],
      child: StripesHome(
        locale: config.locale,
        delegates: config.localizationDelegates,
        builder: config.builder,
      ),
    );
  }
}

class StripesHome extends ConsumerWidget {
  final Locale? locale;

  final List<LocalizationsDelegate>? delegates;

  final Widget Function(BuildContext, Widget?)? builder;
  const StripesHome(
      {required this.locale, this.delegates, this.builder, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routeProvider);
    return _EarlyInit(
        child: MaterialApp.router(
      restorationScopeId: "stripes-restoration",
      locale: locale,
      debugShowCheckedModeBanner: false,
      title: 'Stripes',
      builder: builder,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        if (delegates != null) ...delegates!
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: light.copyWith(
        tooltipTheme: tooltipTheme(context),
      ),
      //darkTheme: dark,
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    ));
  }
}

class _EarlyInit extends ConsumerWidget {
  final Widget child;

  const _EarlyInit({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStream);
    ref.watch(subHolderProvider);
    ref.watch(stampsStreamProvider);
    ref.watch(testStreamProvider);

    return child;
  }
}
