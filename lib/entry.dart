// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/route_provider.dart';
import 'package:stripes_ui/UI/History/EventView/entry_display.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/Util/palette.dart';

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
  void didDisposeProvider(ProviderBase provider, ProviderContainer containers) {
    print('removed provider ${provider.runtimeType}');
    super.didDisposeProvider(provider, containers);
  }
}

final reposProvider = Provider<StripesRepoPackage>((ref) => LocalRepoPackage());

typedef ExportAction = Function(List<Response> responses);

final exportProvider = Provider<ExportAction?>((ref) => null);

final hasGraphingProvider = StateProvider((ref) => true);

final authStrat = Provider<AuthStrat>((ref) => AuthStrat.accessCode);

enum AuthStrat {
  accessCodeEmail,
  accessCode;
}

class StripesApp extends StatelessWidget {
  final bool hasLogging, hasGraphing;

  final StripesRepoPackage? repos;

  final ExportAction? exportAction;

  final Map<String, Widget Function(Response<Question>)>? displayOverrides;

  final Map<String, QuestionEntry>? entryOverrides;

  final AuthStrat strat;

  const StripesApp(
      {this.repos,
      this.hasLogging = false,
      this.hasGraphing = true,
      this.displayOverrides,
      this.exportAction,
      this.entryOverrides,
      this.strat = AuthStrat.accessCode,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        hasGraphingProvider.overrideWith((ref) => hasGraphing),
        if (repos != null) reposProvider.overrideWithValue(repos!),
        if (entryOverrides != null)
          questionEntryOverides.overrideWithValue(entryOverrides!),
        if (displayOverrides != null)
          questionDisplayOverides.overrideWithValue(displayOverrides!),
        if (exportAction != null)
          exportProvider.overrideWithValue(exportAction),
        authStrat.overrideWithValue(strat),
      ],
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
      locale: const Locale('de'),
      debugShowCheckedModeBanner: false,
      title: 'Stripes Tracker',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
