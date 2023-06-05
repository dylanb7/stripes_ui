import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_ui/UI/Login/landing_page.dart';
import 'package:stripes_ui/UI/Login/sign_up.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/UI/PatientManagement/PatientScreen/patient_screen.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/splitter.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/symptom_record_data.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';

import '../UI/Login/login.dart';

final routeProvider = Provider<GoRouter>((ref) {
  final RouteNotifier router = RouteNotifier(ref);
  return GoRouter(
      debugLogDiagnostics: false,
      refreshListenable: router,
      redirect: router._redirect,
      initialLocation: Routes.LANDING,
      routes: router._routes);
});

class RouteNotifier extends ChangeNotifier {
  final Ref _ref;

  RouteNotifier(this._ref) {
    _ref.listen(currentAuthProvider, (previous, next) {
      notifyListeners();
    });
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final bool auth = !AuthUser.isEmpty(_ref.read(currentAuthProvider));
    final String loc = state.location;
    final bool noAuthRoute = Routes.noauth.contains(loc);

    if (noAuthRoute && auth) {
      return Routes.HOME;
    } else if (!noAuthRoute && !auth) {
      return Routes.LANDING;
    }
    return null;
  }

  List<GoRoute> get _routes => [
        GoRoute(
          path: Routes.SIGN_UP,
          pageBuilder: (context, state) =>
              FadeIn(child: const Scaff(child: SignUpPage()), state: state),
        ),
        GoRoute(
          path: Routes.LOGIN,
          pageBuilder: (context, state) =>
              FadeIn(child: const Scaff(child: Login()), state: state),
        ),
        GoRoute(
            path: Routes.LANDING,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LandingPage())),
        GoRoute(
          path: Routes.USERS,
          pageBuilder: (context, state) =>
              FadeIn(child: const Scaff(child: PatientScreen()), state: state),
        ),
        GoRoute(
          path: Routes.HISTORY,
          pageBuilder: (context, state) => const NoTransitionPage(
              child: Home(path: NavPath(option: TabOption.history))),
        ),
        GoRoute(
          path: Routes.HOME,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Home(
              path: NavPath(option: TabOption.record),
            ),
          ),
        ),
        GoRoute(
          name: Routes.TEST,
          path: '${Routes.HOME}/${Routes.TEST}',
          pageBuilder: (context, state) => FadeIn(
            state: state,
            child: const TestScreen(),
          ),
        ),
        GoRoute(
          path: '${Routes.HOME}/:type',
          name: 'recordType',
          pageBuilder: (context, state) {
            final String? type = state.pathParameters['type'];
            if (type == null) return FadeIn(state: state, child: Container());
            return FadeIn(
                child: RecordSplitter(type: type, data: _data(state)),
                state: state);
          },
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

  SymptomRecordData _data(GoRouterState state) {
    if (state.extra == null || state.extra is! SymptomRecordData) {
      return SymptomRecordData.empty;
    }
    return state.extra as SymptomRecordData;
  }
}

class FadeIn extends CustomTransitionPage<void> {
  FadeIn({
    required GoRouterState state,
    required Widget child,
  }) : super(
            key: state.pageKey,
            child: child,
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
                  opacity: animation.drive(_curveTween),
                  child: child,
                ));

  static final CurveTween _curveTween = CurveTween(curve: Curves.easeIn);
}

class Scaff extends StatelessWidget {
  final Widget child;

  const Scaff({required this.child, Key? key}) : super(key: key);

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
