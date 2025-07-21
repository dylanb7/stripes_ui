// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/route_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/config.dart';

import 'l10n/app_localizations.dart';

class Logger extends ProviderObserver {
  const Logger();
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('''
{
  "provider": "${provider.name ?? provider.runtimeType}",
  "newValue": "$newValue"
}''');
  }

  @override
  void didAddProvider(
      ProviderBase provider, Object? value, ProviderContainer container) {
    print('added provider ${provider.runtimeType}');
    super.didAddProvider(provider, value, container);
  }

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    print('removed provider ${provider.runtimeType}');
    super.didDisposeProvider(provider, container);
  }
}

final reposProvider = Provider<StripesRepoPackage>((ref) => LocalRepoPackage());

final configProvider =
    Provider<StripesConfig>((ref) => const StripesConfig.sandbox());

class StripesApp extends StatelessWidget {
  final StripesRepoPackage? repos;

  final StripesConfig config;

  const StripesApp(
      {this.repos, this.config = const StripesConfig.sandbox(), super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        configProvider.overrideWith((ref) => config),
        if (repos != null) reposProvider.overrideWith((ref) => repos!)
      ],
      observers: [if (config.hasLogging) const Logger()],
      child: StripesHome(
        locale: config.locale,
        builder: config.builder,
      ),
    );
  }
}

class StripesHome extends ConsumerWidget {
  final Locale? locale;

  final Widget Function(BuildContext, Widget?)? builder;
  const StripesHome({required this.locale, this.builder, super.key});

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.from(
          colorScheme: ColorScheme.dark(primary: Color(0xff1460a5))),
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
    ref.watch(stampHolderProvider);
    ref.watch(testStreamProvider);

    return child;
  }
}
