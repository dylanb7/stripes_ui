import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/base_test_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/test_state.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/Util/constants.dart';

import 'package:stripes_ui/l10n/app_localizations.dart';

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  Test? selected;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TestsState> testsState = ref.watch(testsHolderProvider);
    final Test<TestState>? selectedTest = ref.watch(testsHolderProvider
            .select((state) => state.valueOrNull?.selected)) ??
        testsState.valueOrNull?.testsRepo?.tests.first;
    if (selectedTest == null) {
      return const LoadingWidget();
    }
    return selectedTest.displayState(context) ?? const SizedBox();
  }
}

class TestSwitcher extends ConsumerWidget {
  const TestSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TestsState> testsState = ref.watch(testsHolderProvider);

    return testsState.map<Widget>(data: (AsyncData<TestsState> data) {
      final List<Test> tests = data.value.testsRepo?.tests ?? [];
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          tests.length == 1
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tests[0].getName(context),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor),
                    textAlign: TextAlign.left,
                  ),
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButton<Test>(
                    items: tests
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.getName(context),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor),
                                textAlign: TextAlign.left,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) async {
                      if (val == null) return;

                      await ref
                          .read(testsHolderProvider.notifier)
                          .changeCurrent(val);
                    },
                    value: data.value.selected,
                  ),
                ),
        ],
      );
    }, error: (AsyncError<TestsState> error) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          error.error.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor),
          textAlign: TextAlign.left,
        ),
      );
    }, loading: (AsyncLoading<TestsState> loading) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          "...",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor),
          textAlign: TextAlign.left,
        ),
      );
    });
  }
}

class TestErrorPrevention<T extends Test> extends ConsumerWidget {
  const TestErrorPrevention({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmationPopup(
        title: Text(
          AppLocalizations.of(context)!.errorPreventionTitle,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.blueMuffinErrorPreventionLineOne,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 8.0,
            ),
            Text(
              AppLocalizations.of(context)!.blueMuffinErrorPreventionLineTwo,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        onConfirm: () async {
          (await ref.read(testsHolderProvider.notifier).getTest<T>())?.cancel();
        },
        cancel: AppLocalizations.of(context)!.errorPreventionStay,
        confirm: AppLocalizations.of(context)!.errorPreventionLeave);
  }
}
