import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_ui/Providers/graph_packets.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/symptom_management_screen.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/symptom_type_management.dart';
import 'package:stripes_ui/UI/AccountManagement/account_management_screen.dart';
import 'package:stripes_ui/UI/History/GraphView/graphs_list.dart';
import 'package:stripes_ui/UI/Login/landing_page.dart';

import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/ProfileScreen/profile_screen.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/splitter.dart';

import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/paddings.dart';

final routeProvider = Provider<GoRouter>((ref) {
  final RouteNotifier router = RouteNotifier(ref);
  return GoRouter(
      debugLogDiagnostics: false,
      refreshListenable: router,
      /*redirect: router._redirect,*/
      initialLocation: Routes.HOME,
      routes: router._routes);
});

class RouteNotifier extends ChangeNotifier {
  final Ref _ref;

  RouteNotifier(this._ref) {
    _ref.listen(authStream, (previous, next) {
      notifyListeners();
    });
  }

  /*String? _redirect(BuildContext context, GoRouterState state) {
    final bool auth = !AuthUser.isEmpty(_ref.read(authStream).map(
        data: (val) => val.value,
        error: (val) => const AuthUser.empty(),
        loading: (val) => const AuthUser.empty()));
    final String loc = state.location;
    final bool noAuthRoute = Routes.noauth.contains(loc);

    if (noAuthRoute && auth) {
      return Routes.HOME;
    } else if (!noAuthRoute && !auth) {
      return Routes.LANDING;
    }
    return null;
  }*/

  List<GoRoute> get _routes => [
        GoRoute(
          path: Routes.SIGN_UP,
          pageBuilder: (context, state) =>
              FadeIn(child: const Scaff(child: SizedBox()), state: state),
        ),
        GoRoute(
          path: Routes.LOGIN,
          pageBuilder: (context, state) =>
              FadeIn(child: const Scaff(child: SizedBox()), state: state),
        ),
        GoRoute(
            path: Routes.LANDING,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LandingPage())),
        GoRoute(
          name: Routes.ACCOUNT,
          path: Routes.ACCOUNT,
          routes: [
            GoRoute(
              name: Routes.USERS,
              path: Routes.USERS,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PatientScreen()),
            ),
            GoRoute(
                name: Routes.SYMPTOMS,
                path: Routes.SYMPTOMS,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SymptomManagementScreen()),
                routes: [
                  GoRoute(
                    path: ':type',
                    name: Routes.SYMPTOMTYPE,
                    pageBuilder: (context, state) {
                      final String? type = state.pathParameters['type'];

                      return NoTransitionPage(
                        child: SymptomTypeManagement(
                          category: type,
                        ),
                      );
                    },
                  )
                ]),
          ],
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AccountManagementScreen()),
        ),
        GoRoute(
          name: Routes.HISTORY,
          path: Routes.HISTORY,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Home(
              selected: TabOption.history,
            ),
          ),
        ),
        GoRoute(
          path: Routes.HOME,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Home(
              selected: TabOption.record,
            ),
          ),
        ),
        GoRoute(
            name: Routes.TRENDS,
            path: Routes.TRENDS,
            pageBuilder: (context, state) => const NoTransitionPage(
                  child: GraphsList(),
                ),
            routes: [
              GoRoute(
                  name: Routes.SYMPTOMTREND,
                  path: Routes.SYMPTOMTREND,
                  pageBuilder: (context, state) {
                    if (state.extra is! GraphKey) {
                      return const NoTransitionPage(child: GraphsList());
                    }

                    return FadeIn(
                      state: state,
                      child: GraphViewScreen(
                        graphKey: state.extra as GraphKey,
                      ),
                    );
                  }),
            ]),
        GoRoute(
          name: Routes.TEST,
          path: Routes.TEST,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Home(
              selected: TabOption.tests,
            ),
          ),
        ),
        GoRoute(
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
                      const SizedBox(
                        height: AppPadding.small,
                      ),
                      TextButton(
                          onPressed: () {
                            context.pop();
                          },
                          child: const Text("Back"))
                    ],
                  ),
                ),
              );
            }
            return FadeIn(
                child: RecordSplitter(type: type, data: _data(state)),
                state: state);
          },
        ),
        GoRoute(
          name: Routes.SETTINGS,
          path: Routes.SETTINGS,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Home(
              selected: TabOption.tests,
            ),
          ),
        ),
        /*
        GoRoute(
          name: Routes.BM,
          path: '${Routes.HOME}/${Routes.BM}',
          pageBuilder: (context, state) =>
              FadeIn(child: BowelMovementLog(data: _data(state)), state: state),
        ),
        GoRoute(
          name: Routes.NB,
          path: '${Routes.HOME}/${Routes.NB}',
          pageBuilder: (context, state) => FadeIn(
              child: NeurologicalBehaviorsLog(data: _data(state)),
              state: state),
        ),
        GoRoute(
          name: Routes.PAIN,
          path: '${Routes.HOME}/${Routes.PAIN}',
          pageBuilder: (context, state) =>
              FadeIn(child: PainLog(data: _data(state)), state: state),
        ),
        GoRoute(
          name: Routes.REFLUX,
          path: '${Routes.HOME}/${Routes.REFLUX}',
          pageBuilder: (context, state) =>
              FadeIn(child: RefluxLog(data: _data(state)), state: state),
        ),
        */
      ];

  QuestionsListener? _data(GoRouterState state) {
    if (state.extra == null || state.extra is! QuestionsListener) {
      return null;
    }
    return state.extra as QuestionsListener;
  }
}

class FadeIn extends CustomTransitionPage<void> {
  FadeIn({
    required GoRouterState state,
    required super.child,
  }) : super(
            key: state.pageKey,
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
                  opacity: animation.drive(_curveTween),
                  child: child,
                ));

  static final CurveTween _curveTween = CurveTween(curve: Curves.easeIn);
}

class Scaff extends StatelessWidget {
  final Widget child;

  const Scaff({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: child,
      ),
    );
  }
}
