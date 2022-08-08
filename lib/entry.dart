// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/repo_package.dart';
import 'package:stripes_ui/Providers/repos_provider.dart';
import 'package:stripes_ui/Providers/route_provider.dart';
import 'package:stripes_ui/Util/palette.dart';

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
  void didDisposeProvider(ProviderBase provider, ProviderContainer containers) {
    print('removed provider ${provider.runtimeType}');
    super.didDisposeProvider(provider, containers);
  }
}

class StripesApp extends StatelessWidget {
  final bool hasLogging;

  final StripesRepoPackage? repos;

  const StripesApp({this.repos, this.hasLogging = false, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [if (repos != null) reposProvider.overrideWithValue(repos!)],
      observers: [if (hasLogging) const Logger()],
      child: const StripesHome(),
    );
  }
}

class StripesHome extends ConsumerWidget {
  const StripesHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Stripes Tracker',
      theme: ThemeData(
        splashColor: null,
        splashFactory: NoSplash.splashFactory,
        primarySwatch: Colors.blue,
        timePickerTheme: TimePickerThemeData(
            dialHandColor: buttonDarkBackground,
            hourMinuteColor: buttonDarkBackground.withOpacity(0.12),
            dayPeriodTextColor: lightBackgroundText,
            hourMinuteTextColor: buttonDarkBackground),
      ),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }
}
