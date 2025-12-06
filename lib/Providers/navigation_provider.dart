import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/sheet_provider.dart';

final navigationControllerProvider = Provider<NavigationController>((ref) {
  return NavigationController(ref);
});

typedef NavigationGuard = Future<bool> Function(BuildContext);

final registerGuardProvider =
    Provider.family.autoDispose<void, NavigationGuard>((ref, guard) {
  final NavigationController controller =
      ref.read(navigationControllerProvider);
  controller.addGuard(guard);
  ref.onDispose(() => controller.removeGuard(guard));
});

class NavigationController {
  final Ref ref;
  final Set<NavigationGuard> _guards = {};

  NavigationController(this.ref);

  void addGuard(NavigationGuard guard) {
    if (!_guards.contains(guard)) {
      _guards.add(guard);
    }
  }

  void removeGuard(NavigationGuard guard) {
    _guards.remove(guard);
  }

  Future<bool> _checkGuards(BuildContext context) async {
    for (final guard in _guards) {
      final bool canProceed = await guard(context);
      if (!canProceed) return false;
    }
    return true;
  }

  Future<void> navigate(BuildContext context, String route,
      {Object? extra}) async {
    if (!await _checkGuards(context)) return;

    if (context.mounted) _handleSheetClose(context);

    if (context.mounted) {
      context.go(route, extra: extra);
    }
  }

  Future<void> push(BuildContext context, String route, {Object? extra}) async {
    if (!await _checkGuards(context)) return;

    if (context.mounted) _handleSheetClose(context);

    if (context.mounted) {
      context.push(route, extra: extra);
    }
  }

  Future<void> pushNamed(BuildContext context, String name,
      {Object? extra,
      Map<String, String> pathParameters = const <String, String>{},
      Map<String, dynamic> queryParameters = const <String, dynamic>{}}) async {
    if (!await _checkGuards(context)) return;

    if (context.mounted) _handleSheetClose(context);

    if (context.mounted) {
      context.pushNamed(name,
          extra: extra,
          pathParameters: pathParameters,
          queryParameters: queryParameters);
    }
  }

  Future<void> pop(BuildContext context) async {
    if (!await _checkGuards(context)) return;

    if (context.mounted) _handleSheetClose(context);

    if (context.mounted) {
      context.pop();
    }
  }

  void _handleSheetClose(BuildContext context) {
    if (ref.read(isSheetOpenProvider)) {
      if (context.canPop()) {
        ref.read(isSheetOpenProvider.notifier).state = false;
        context.pop();
      }
    }
  }
}
