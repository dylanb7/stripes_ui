import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Models/baseline_trigger.dart';
import 'package:stripes_ui/Providers/questions/baseline_trigger_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';

class BaselineGate extends ConsumerWidget {
  final Widget child;

  const BaselineGate({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SubState> subState = ref.watch(subHolderProvider);
    if (subState.isLoading) {
      return child;
    }
    final SubState? state = subState.valueOrNull;
    if (state == null ||
        state.subUsers.isEmpty ||
        state.selected == null ||
        SubUser.isEmpty(state.selected!)) {
      return child;
    }

    final AsyncValue<List<BaselineTrigger>> activeTriggers =
        ref.watch(activeBaselineTriggersProvider);

    return activeTriggers.when(
      data: (triggers) {
        if (triggers.isEmpty) {
          return child;
        }
        return _BaselineGateOverlay(
          triggers: triggers,
          child: child,
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

class _BaselineGateOverlay extends ConsumerStatefulWidget {
  final List<BaselineTrigger> triggers;
  final Widget child;

  const _BaselineGateOverlay({
    required this.triggers,
    required this.child,
  });

  @override
  ConsumerState<_BaselineGateOverlay> createState() =>
      _BaselineGateOverlayState();
}

class _BaselineGateOverlayState extends ConsumerState<_BaselineGateOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Durations.medium1,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.8, -1.5),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInBack,
    ));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInBack,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismissWithAnimation() async {
    setState(() => _isDismissing = true);
    await _animationController.forward();
    for (final trigger in widget.triggers) {
      ref.read(baselineDismissProvider.notifier).dismiss(trigger.baselineType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Block interaction with child by wrapping in IgnorePointer
        IgnorePointer(
          ignoring: true,
          child: widget.child,
        ),
        // Animated scrim
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Container(
              color:
                  colors.scrim.withValues(alpha: 0.85 * _fadeAnimation.value),
            );
          },
        ),
        // Animated modal
        SafeArea(
          child: Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: Breakpoint.small.value),
                    child: Padding(
                      padding: const EdgeInsets.all(AppPadding.large),
                      child: Material(
                        elevation: 16,
                        borderRadius: BorderRadius.circular(AppRounding.large),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colors.surface,
                                colors.surfaceContainerLow,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header with gradient
                              Container(
                                padding: const EdgeInsets.all(AppPadding.large),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colors.primary,
                                      colors.primary.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                          AppPadding.medium),
                                      decoration: BoxDecoration(
                                        color: colors.onPrimary
                                            .withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.assignment_outlined,
                                        size: 40,
                                        color: colors.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppPadding.medium),
                                    Text(
                                      'Complete Baselines',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colors.onPrimary,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppPadding.small),
                                    Text(
                                      'Please complete the following to continue',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: colors.onPrimary
                                                .withValues(alpha: 0.9),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              // Baseline list
                              Padding(
                                padding:
                                    const EdgeInsets.all(AppPadding.medium),
                                child: Column(
                                  children: [
                                    ...widget.triggers.map(
                                      (trigger) => BaselineTriggerTile(
                                        trigger: trigger,
                                        onStart: _dismissWithAnimation,
                                      ),
                                    ),
                                    const SizedBox(height: AppPadding.medium),
                                    // Remind Me Later button with animation
                                    TextButton.icon(
                                      onPressed: _isDismissing
                                          ? null
                                          : _dismissWithAnimation,
                                      icon: Icon(
                                        Icons.schedule,
                                        color: colors.outline,
                                      ),
                                      label: Text(
                                        'Remind Me Later',
                                        style: TextStyle(color: colors.outline),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BaselineTriggerTile extends ConsumerWidget {
  final BaselineTrigger trigger;
  final VoidCallback? onStart;

  const BaselineTriggerTile({required this.trigger, this.onStart, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRounding.small),
        color: colors.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.medium,
          vertical: AppPadding.small,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppPadding.small),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRounding.tiny),
              ),
              child: Icon(
                Icons.edit_note,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppPadding.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trigger.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppPadding.tiny),
                  Text(
                    trigger.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppPadding.small),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () async {
                        // Dismiss the gate overlay first
                        onStart?.call();
                        // URL encode the recordPath to handle special characters
                        final encoded = Uri.encodeComponent(trigger.recordPath);
                        await context.pushNamed(
                          RouteName.BASELINE_ENTRY,
                          pathParameters: {'recordPath': encoded},
                        );
                        if (context.mounted) {
                          ref.invalidate(baselinesStreamProvider);
                        }
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Start'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
