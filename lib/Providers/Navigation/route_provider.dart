import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/symptom_management_screen.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/symptom_type_management.dart';
import 'package:stripes_ui/UI/AccountManagement/account_management_screen.dart';
import 'package:stripes_ui/UI/AccountManagement/baselines_section.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_view_screen.dart';

import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/ProfileScreen/profile_screen.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_onboarding_wizard.dart';
import 'package:stripes_ui/UI/AccountManagement/terms_onboarding_gate.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/baseline_entry.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/record_entry.dart';
import 'package:stripes_ui/UI/Record/MultiRecord/multi_record_screen.dart';
import 'package:stripes_ui/UI/Resources/resources.dart';

import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routeProvider = Provider<GoRouter>((ref) {
  final RouteNotifier router = RouteNotifier(ref);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: false,
    refreshListenable: router,
    /*redirect: router._redirect,*/
    initialLocation: Routes.HOME,
    extraCodec: MainExtraCodec(ref),
    routes: router._routes,
  );
});

class RouteNotifier extends ChangeNotifier {
  final Ref _ref;

  RouteNotifier(this._ref) {
    _ref.listen(authStream, (previous, next) {
      notifyListeners();
    });
  }

  List<RouteBase> get _routes => [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      pageBuilder: (context, state, child) {
        final bool isSmall = getBreakpoint(context)
            .isLessThan(Breakpoint.medium);

        TabOption? selected;

        final List<String> pathSegments = state.uri.pathSegments;

        bool inAccount = pathSegments[0] == RouteName.ACCOUNT;

        if (pathSegments.length == 1) {
          final int currentTabIndex = [
            RouteName.HOME,
            RouteName.TEST,
            RouteName.HISTORY,
          ].indexOf(pathSegments[0]);
          selected = currentTabIndex == -1
              ? null
              : TabOption.values[currentTabIndex];
        }

        return NoTransitionPage(
          child: TermsOnboardingGate(
            child: PageWrap(
              floating: true,
              actions: [
                if (!isSmall)
                  ...TabOption.values
                      .map(
                        (tab) => LargeNavButton(tab: tab, selected: selected),
                      )
                      .separated(
                        by: const SizedBox(width: AppPadding.small),
                        includeEnds: true,
                      ),
                UserProfileButton(selected: inAccount),
              ],
              bottomNav: isSmall && selected != null
                  ? SmallLayout(selected: selected)
                  : null,
              child: child,
            ),
          ),
        );
      },
      routes: [
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          name: RouteName.ACCOUNT,
          path: Routes.ACCOUNT,
          routes: [
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              name: RouteName.RESOURCES,
              path: Routes.RESOURCES,
              pageBuilder: (context, state) =>
                  FadeIn(child: _resourcesScreen(context), state: state),
              routes: [
                GoRoute(
                  parentNavigatorKey: _shellNavigatorKey,
                  name: RouteName.RESOURCE,
                  path: Routes.RESOURCE,
                  pageBuilder: (context, state) {
                    final topic = ResourceTopic.fromSlug(
                      state.pathParameters['topic'] ?? '',
                    );
                    return FadeIn(
                      state: state,
                      child: topic == null
                          ? _resourcesScreen(context)
                          : ResourceScreen(
                              topic: topic,
                              onOpenResource: (related) => context.pushNamed(
                                RouteName.RESOURCE,
                                pathParameters: {'topic': related.slug},
                              ),
                              onBack: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.goNamed(RouteName.RESOURCES);
                                }
                              },
                            ),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              name: RouteName.USERS,
              path: Routes.USERS,
              pageBuilder: (context, state) =>
                  FadeIn(child: const PatientScreen(), state: state),
              routes: [
                GoRoute(
                  parentNavigatorKey: _shellNavigatorKey,
                  name: RouteName.ADD_PROFILE,
                  path: Routes.ADD_PROFILE,
                  pageBuilder: (context, state) => FadeIn(
                    state: state,
                    child: Scaffold(
                      body: SafeArea(
                        child: ProfileOnboardingWizard(
                          title: 'New Profile',
                          subtitle: "Who are we tracking today?",
                          headerIcon: Icons.person_add_alt_1_outlined,
                          onFinished: () {
                            if (context.canPop()) context.pop();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              name: RouteName.BASELINES,
              path: Routes.BASELINES,
              pageBuilder: (context, state) =>
                  FadeIn(child: const BaselinesScreen(), state: state),
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              name: RouteName.BASELINE_ENTRY,
              path: Routes.BASELINE_ENTRY,
              pageBuilder: (context, state) {
                final String? recordPath = state.pathParameters['recordPath'];
                if (recordPath == null) {
                  return FadeIn(
                    child: const Scaffold(
                      body: Center(child: Text('Invalid baseline')),
                    ),
                    state: state,
                  );
                }

                final String decodedPath = Uri.decodeComponent(recordPath);
                return FadeIn(
                  child: Scaffold(
                    body: SafeArea(
                      child: BaselineEntry(recordPath: decodedPath),
                    ),
                  ),
                  state: state,
                );
              },
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              name: RouteName.SYMPTOMS,
              path: Routes.SYMPTOMS,
              pageBuilder: (context, state) =>
                  _ref.read(configProvider).betaUi.hasSymptomEditing
                  ? FadeIn(child: const SymptomManagementScreen(), state: state)
                  : const NoTransitionPage(child: AccountManagementScreen()),
              routes: [
                GoRoute(
                  parentNavigatorKey: _shellNavigatorKey,
                  path: ':type',
                  name: RouteName.SYMPTOMTYPE,
                  pageBuilder: (context, state) {
                    if (!_ref.read(configProvider).betaUi.hasSymptomEditing) {
                      return const NoTransitionPage(
                        child: AccountManagementScreen(),
                      );
                    }
                    final String? type = state.pathParameters['type'];

                    return FadeIn(
                      child: SymptomTypeManagement(category: type),
                      state: state,
                    );
                  },
                ),
              ],
            ),
          ],
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AccountManagementScreen()),
        ),
        GoRoute(
          name: RouteName.HISTORY,
          path: Routes.HISTORY,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Home(selected: TabOption.history)),
          routes: [
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              name: RouteName.SYMPTOMTREND,
              path: Routes.SYMPTOMTREND,
              pageBuilder: (context, state) {
                if (!_ref.read(configProvider).betaUi.hasGraphing) {
                  return const NoTransitionPage(
                    child: Home(selected: TabOption.history),
                  );
                }
                if (state.extra is GraphViewParams) {
                  final params = state.extra as GraphViewParams;
                  return FadeIn(
                    state: state,
                    child: GraphViewScreen(
                      graphKey: params.graphKey,
                      initialAdditions: params.initialAdditions,
                    ),
                  );
                }
                if (state.extra is GraphKey) {
                  return FadeIn(
                    state: state,
                    child: GraphViewScreen(graphKey: state.extra as GraphKey),
                  );
                }
                return const NoTransitionPage(
                  child: Home(selected: TabOption.history),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: Routes.HOME,
          name: RouteName.HOME,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Home(selected: TabOption.record)),
        ),
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          name: RouteName.TEST,
          path: Routes.TEST,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Home(selected: TabOption.tests)),
        ),
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          path: Routes.MULTI_RECORD,
          name: RouteName.MULTI_RECORD,
          pageBuilder: (context, state) =>
              _ref.read(configProvider).betaUi.multiSessionFlow
              ? FadeIn(
                  state: state,
                  child: MultiRecordScreen(
                    initialCategory: state.uri.queryParameters['category'],
                  ),
                )
              : const NoTransitionPage(child: Home(selected: TabOption.record)),
        ),
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          path: '${Routes.HOME}/:type',
          name: 'recordType',
          pageBuilder: (context, state) {
            final String? type = state.pathParameters['type'];
            if (type == null) {
              return FadeIn(
                state: state,
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Path does not exist"),
                      const SizedBox(height: AppPadding.small),
                      TextButton(
                        onPressed: () {
                          context.pop();
                        },
                        child: const Text("Back"),
                      ),
                    ],
                  ),
                ),
              );
            }
            return FadeIn(
              child: RecordSplitter(type: type, data: _data(state)),
              state: state,
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          name: RouteName.SETTINGS,
          path: Routes.SETTINGS,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Home(selected: TabOption.tests)),
        ),
      ],
    ),
  ];

  SessionData? _data(GoRouterState state) {
    if (state.extra == null || state.extra is! SessionData) {
      return null;
    }
    return state.extra as SessionData;
  }

  List<GoRoute> matchedRoutes({required BuildContext context}) {
    final GoRouter router = GoRouter.of(context);
    final GoRouterDelegate routerDelegate = router.routerDelegate;
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.matches.whereType<GoRoute>().toList();
  }
}

ResourcesScreen _resourcesScreen(BuildContext context) => ResourcesScreen(
  onOpenResource: (topic) => context.pushNamed(
    RouteName.RESOURCE,
    pathParameters: {'topic': topic.slug},
  ),
  onBack: () {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteName.ACCOUNT);
    }
  },
);

class FadeIn extends CustomTransitionPage<void> {
  FadeIn({required GoRouterState state, required super.child})
    : super(
        key: state.pageKey,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation.drive(_curveTween), child: child),
      );

  static final CurveTween _curveTween = CurveTween(curve: Curves.easeIn);
}

class MainExtraCodec extends Codec<Object?, Object?> {
  final Ref ref;

  const MainExtraCodec(this.ref);

  @override
  Converter<Object?, Object?> get decoder => _MainExtraDecoder(ref);

  @override
  Converter<Object?, Object?> get encoder => const _MainExtraEncoder();
}

class _MainExtraDecoder extends Converter<Object?, Object?> {
  final Ref ref;

  const _MainExtraDecoder(this.ref);

  @override
  Object? convert(Object? input) {
    if (input == null) {
      return null;
    }
    if (input is Map<String, dynamic>) {
      if (input['__type'] == 'GraphViewParams') {
        return GraphViewParams.fromJson(input);
      }
      if (input['__type'] == 'GraphKey') {
        return GraphKey.fromJson(input);
      }
      if (input['__type'] == 'SessionData') {
        final QuestionHome? home = ref.read(questionHomeProvider).value;
        if (home != null) {
          return SessionData.fromJson(input, home);
        }
      }
    }
    return null;
  }
}

class _MainExtraEncoder extends Converter<Object?, Object?> {
  const _MainExtraEncoder();

  @override
  Object? convert(Object? input) {
    if (input == null) {
      return null;
    }
    if (input is SessionData) {
      return input.toJson()..['__type'] = 'SessionData';
    }
    if (input is GraphViewParams) {
      return input.toJson();
    }
    if (input is GraphKey) {
      return input.toJson()..['__type'] = 'GraphKey';
    }
    return input;
  }
}
