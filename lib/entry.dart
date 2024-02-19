// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/route_provider.dart';
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

typedef ExportAction = Future<void> Function(List<Response> responses);

final exportProvider = Provider<ExportAction?>((ref) => null);

final exitStudyProvider = Provider<Function?>((ref) => null);

final hasGraphingProvider = StateProvider((ref) => true);

final authStrat = Provider<AuthStrat>((ref) => AuthStrat.accessCode);

enum AuthStrat {
  accessCodeEmail,
  accessCode;
}

class StripesApp extends StatelessWidget {
  final bool hasLogging, hasGraphing;

  final Locale locale;

  final StripesRepoPackage? repos;

  final ExportAction? exportAction;

  final Function? removeTrace;

  final AuthStrat strat;

  final Widget Function(BuildContext, Widget?)? builder;

  const StripesApp(
      {this.repos,
      this.hasLogging = false,
      this.hasGraphing = true,
      this.locale = const Locale('en'),
      this.removeTrace,
      this.exportAction,
      this.builder,
      this.strat = AuthStrat.accessCode,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        hasGraphingProvider.overrideWith((ref) => hasGraphing),
        if (repos != null) reposProvider.overrideWithValue(repos!),
        if (exportAction != null)
          exportProvider.overrideWithValue(exportAction),
        if (removeTrace != null)
          exitStudyProvider.overrideWithValue(removeTrace),
        authStrat.overrideWithValue(strat),
      ],
      observers: [if (hasLogging) const Logger()],
      child: StripesHome(
        locale: locale,
        builder: builder,
      ),
    );
  }
}

class StripesHome extends ConsumerWidget {
  final Locale locale;

  final Widget Function(BuildContext, Widget?)? builder;
  const StripesHome({required this.locale, this.builder, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routeProvider);
    return MaterialApp.router(
      locale: locale,
      debugShowCheckedModeBanner: false,
      title: 'Stripes Tracker',
      builder: builder,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme:
          light /*.copyWith(
          textTheme: GoogleFonts.atkinsonHyperlegibleTextTheme(
              Theme.of(context).textTheme))*/
      ,
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }
}
