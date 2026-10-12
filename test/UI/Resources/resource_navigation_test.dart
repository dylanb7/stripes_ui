import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/Navigation/route_provider.dart';
import 'package:stripes_ui/UI/Resources/resources.dart';
import 'package:stripes_ui/Util/constants.dart';

void main() {
  testWidgets('every guide has a stable route beneath Account resources', (
    tester,
  ) async {
    final production = _productionRouter();
    expect(production.namedLocation(RouteName.RESOURCES), '/account/resources');
    for (final topic in ResourceTopic.values) {
      final location = production.namedLocation(
        RouteName.RESOURCE,
        pathParameters: {'topic': topic.slug},
      );
      expect(location, '/account/resources/${topic.slug}');
      final match = production.configuration.findMatch(Uri.parse(location));
      expect(match.isError, isFalse);
      expect(match.pathParameters['topic'], topic.slug);
      expect(match.last.route.name, RouteName.RESOURCE);
    }
  });

  testWidgets('hub, related guides, and back use the resource route stack', (
    tester,
  ) async {
    final router = await _pumpResourceRoutes(tester);
    await _openGuide(tester, ResourceTopic.blueMealStudy);
    expect(router.state.uri.path, '/account/resources/blue-meal-study');
    expect(
      tester.widget<ResourceScreen>(find.byType(ResourceScreen)).topic,
      ResourceTopic.blueMealStudy,
    );

    final related = resourceArticle(ResourceTopic.blueMealStudy)
        .relatedTopics
        .first;
    await _openGuide(tester, related);
    expect(router.state.uri.path, '/account/resources/${related.slug}');
    expect(
      tester.widget<ResourceScreen>(find.byType(ResourceScreen)).topic,
      related,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/account/resources/blue-meal-study');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/account/resources');
    expect(find.byType(ResourcesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown guide shows a usable resource hub', (tester) async {
    final router = await _pumpResourceRoutes(
      tester,
      initialLocation: '/account/resources/missing-guide',
    );
    expect(find.byType(ResourcesScreen), findsOneWidget);
    expect(find.byType(ResourceScreen), findsNothing);

    await _openGuide(tester, ResourceTopic.bristolScale);
    expect(router.state.uri.path, '/account/resources/bristol-scale');
    expect(
      tester.widget<ResourceScreen>(find.byType(ResourceScreen)).topic,
      ResourceTopic.bristolScale,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ResourcesScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/account/resources');
    expect(tester.takeException(), isNull);
  });
}

GoRouter _productionRouter() {
  final container = ProviderContainer(
    overrides: [
      authStream.overrideWith((ref) => const Stream<AuthUser>.empty()),
    ],
  );
  final router = container.read(routeProvider);
  addTearDown(() {
    router.dispose();
    container.dispose();
  });
  return router;
}

Future<GoRouter> _pumpResourceRoutes(
  WidgetTester tester, {
  String initialLocation = '/account/resources',
}) async {
  final production = _productionRouter();
  final account = _allRoutes(production.configuration.routes)
      .singleWhere((route) => route.name == RouteName.ACCOUNT);
  final resources = account.routes.whereType<GoRoute>().singleWhere(
    (route) => route.name == RouteName.RESOURCES,
  );
  // Keep the production page factories and route definitions; omit only the
  // unrelated app shell and account data loading around the resources subtree.
  GoRoute withoutShellKey(GoRoute route) => GoRoute(
    path: route.path,
    name: route.name,
    pageBuilder: route.pageBuilder,
    routes: route.routes.whereType<GoRoute>().map(withoutShellKey).toList(),
  );
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: account.path,
        name: account.name,
        builder: (_, _) => const Scaffold(body: Text('Account')),
        routes: [withoutShellKey(resources)],
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

Iterable<GoRoute> _allRoutes(Iterable<RouteBase> routes) sync* {
  for (final route in routes) {
    if (route is GoRoute) yield route;
    yield* _allRoutes(route.routes);
  }
}

Future<void> _openGuide(WidgetTester tester, ResourceTopic topic) async {
  final tile = find.byWidgetPredicate(
    (widget) => widget is ResourceListTile && widget.article.topic == topic,
  );
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}
