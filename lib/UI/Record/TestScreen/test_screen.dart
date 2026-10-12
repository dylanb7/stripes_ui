import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/Record/TestScreen/stage_ui_registry.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_async_error.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class TestScreen extends ConsumerWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(testProvider)
        .when(
          loading: () => const LoadingWidget(),
          error: (error, stack) => TestAsyncError(error: error),
          data: (repo) => repo == null
              ? const _NoTestsAvailable(message: 'No tests available.')
              : _ActiveProtocolsContent(repo: repo),
        );
  }
}

class _ActiveProtocolsContent extends ConsumerWidget {
  final ModularTestsRepo repo;

  const _ActiveProtocolsContent({required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(activeTestProtocolsProvider)
        .when(
          loading: () => const LoadingWidget(),
          error: (error, stack) => TestAsyncError(error: error),
          data: (protocols) => _buildContent(context, ref, protocols),
        );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<ActiveTestProtocol> activeProtocols,
  ) {
    if (activeProtocols.isEmpty) {
      return const _NoTestsAvailable(message: 'No active test protocols.');
    }

    final activeProtocol = activeProtocols.firstWhere(
      (p) => !p.isCompleted,
      orElse: () => activeProtocols.first,
    );
    final definition = repo.definitions.firstWhereOrNull(
      (d) => d.id == activeProtocol.testId,
    );

    if (definition == null) {
      return Center(
        child: Text('Test definition not found: ${activeProtocol.testId}'),
      );
    }

    final currentStage = definition.stages.firstWhere(
      (s) => s.id == activeProtocol.currentStageId,
      orElse: () => definition.stages.first,
    );
    final registry = ref.watch(stageUiRegistryProvider);
    return KeyedSubtree(
      key: ValueKey('${activeProtocol.id}:${currentStage.id}'),
      child: registry.buildStage(
        context: context,
        protocol: activeProtocol,
        stage: currentStage,
        repo: repo,
      ),
    );
  }
}

class _NoTestsAvailable extends StatelessWidget {
  final String message;

  const _NoTestsAvailable({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

class TestSwitcher extends ConsumerWidget {
  const TestSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(testProvider)
        .when(
          data: (repo) =>
              repo == null ? const SizedBox.shrink() : _ActiveTestLabel(repo),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
  }
}

class _ActiveTestLabel extends ConsumerWidget {
  final ModularTestsRepo repo;

  const _ActiveTestLabel(this.repo);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (repo.definitions.isEmpty) return const SizedBox.shrink();

    return ref
        .watch(activeTestProtocolsProvider)
        .when(
          data: (protocols) {
            final activeProtocol = protocols.firstWhereOrNull(
              (protocol) => !protocol.isCompleted,
            );
            final definition = activeProtocol == null
                ? repo.definitions.first
                : repo.definitions.firstWhereOrNull(
                        (definition) => definition.id == activeProtocol.testId,
                      ) ??
                      repo.definitions.first;
            return _TestSwitcherContent(definition: definition);
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
  }
}

class _TestSwitcherContent extends StatelessWidget {
  final TestDefinition definition;

  const _TestSwitcherContent({required this.definition});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        definition.nameKey,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}

class TestErrorPrevention extends ConsumerWidget {
  const TestErrorPrevention({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement modular test cancellation confirmation
    return const SizedBox.shrink();
  }
}
