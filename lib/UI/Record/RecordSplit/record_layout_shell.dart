import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/Util/paddings.dart';

class RecordEntryController extends ChangeNotifier {
  String _title;
  String? _subtitle;
  int _currentIndex;
  int _totalPages;
  PageController _pageController;
  VoidCallback _onClose;
  bool _isCollapsed;
  bool _isLoading;
  VoidCallback? _onControl;
  String _controlLabel;
  bool _isReady;
  bool _isSubmit;
  String? _errorMessage;
  final VoidCallback? _onDismissError;
  int _totalQuestions;
  int _answeredQuestions;
  int _pendingRequiredCount;

  RecordEntryController({
    required String title,
    String? subtitle,
    required int currentIndex,
    required int totalPages,
    required PageController pageController,
    required VoidCallback onClose,
    bool isCollapsed = false,
    bool isLoading = false,
    VoidCallback? onControl,
    String controlLabel = 'Next',
    bool isReady = true,
    bool isSubmit = false,
    String? errorMessage,
    VoidCallback? onDismissError,
    int totalQuestions = 0,
    int answeredQuestions = 0,
    int pendingRequiredCount = 0,
  })  : _title = title,
        _subtitle = subtitle,
        _currentIndex = currentIndex,
        _totalPages = totalPages,
        _pageController = pageController,
        _onClose = onClose,
        _isCollapsed = isCollapsed,
        _isLoading = isLoading,
        _onControl = onControl,
        _controlLabel = controlLabel,
        _isReady = isReady,
        _isSubmit = isSubmit,
        _errorMessage = errorMessage,
        _onDismissError = onDismissError,
        _totalQuestions = totalQuestions,
        _answeredQuestions = answeredQuestions,
        _pendingRequiredCount = pendingRequiredCount;

  String get title => _title;
  String? get subtitle => _subtitle;
  int get currentIndex => _currentIndex;
  int get totalPages => _totalPages;
  PageController get pageController => _pageController;
  VoidCallback get onClose => _onClose;
  bool get isCollapsed => _isCollapsed;
  bool get isLoading => _isLoading;
  VoidCallback? get onControl => _onControl;
  String get controlLabel => _controlLabel;
  bool get isReady => _isReady;
  bool get isSubmit => _isSubmit;
  String get errorMessage => _errorMessage ?? '';
  int get totalQuestions => _totalQuestions;
  int get answeredQuestions => _answeredQuestions;
  int get pendingRequiredCount => _pendingRequiredCount;

  void update({
    String? title,
    String? subtitle,
    int? currentIndex,
    int? totalPages,
    bool? isCollapsed,
    bool? isLoading,
    VoidCallback? onControl,
    String? controlLabel,
    bool? isReady,
    bool? isSubmit,
    String? errorMessage,
    int? totalQuestions,
    int? answeredQuestions,
    int? pendingRequiredCount,
  }) {
    bool changed = false;
    if (title != null && _title != title) {
      _title = title;
      changed = true;
    }
    if (subtitle != null && _subtitle != subtitle) {
      _subtitle = subtitle;
      changed = true;
    }
    if (currentIndex != null && _currentIndex != currentIndex) {
      _currentIndex = currentIndex;
      changed = true;
    }
    if (totalPages != null && _totalPages != totalPages) {
      _totalPages = totalPages;
      changed = true;
    }
    if (isCollapsed != null && _isCollapsed != isCollapsed) {
      _isCollapsed = isCollapsed;
      changed = true;
    }
    if (isLoading != null && _isLoading != isLoading) {
      _isLoading = isLoading;
      changed = true;
    }
    if (onControl != null) {
      _onControl = onControl;
      changed = true;
    }
    if (controlLabel != null && _controlLabel != controlLabel) {
      _controlLabel = controlLabel;
      changed = true;
    }
    if (isReady != null && _isReady != isReady) {
      _isReady = isReady;
      changed = true;
    }
    if (isSubmit != null && _isSubmit != isSubmit) {
      _isSubmit = isSubmit;
      changed = true;
    }
    if (errorMessage != null && _errorMessage != errorMessage) {
      _errorMessage = errorMessage;
      changed = true;
    }
    if (totalQuestions != null && _totalQuestions != totalQuestions) {
      _totalQuestions = totalQuestions;
      changed = true;
    }
    if (answeredQuestions != null && _answeredQuestions != answeredQuestions) {
      _answeredQuestions = answeredQuestions;
      changed = true;
    }
    if (pendingRequiredCount != null &&
        _pendingRequiredCount != pendingRequiredCount) {
      _pendingRequiredCount = pendingRequiredCount;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void showError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void dismissError() {
    _errorMessage = null;
    _onDismissError?.call();
    notifyListeners();
  }

  void goBack() {
    if (_currentIndex == 0) {
      _onClose();
    } else {
      _pageController.previousPage(
        duration: Durations.medium1,
        curve: Curves.linear,
      );
    }
  }
}

class RecordEntryProvider extends InheritedNotifier<RecordEntryController> {
  const RecordEntryProvider({
    super.key,
    required RecordEntryController controller,
    required super.child,
  }) : super(notifier: controller);

  static RecordEntryController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<RecordEntryProvider>();
    assert(provider != null, 'No RecordEntryProvider found in context');
    return provider!.notifier!;
  }

  static RecordEntryController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RecordEntryProvider>()
        ?.notifier;
  }
}

class RecordEntryShell extends StatelessWidget {
  final Widget content;
  final Widget? header;
  final Widget? divider;
  final Widget? control;
  final Widget? footer;

  const RecordEntryShell({
    super.key,
    required this.content,
    this.header,
    this.divider,
    this.control,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final controller = RecordEntryProvider.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          children: [
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: header ?? const RecordEntryHeader(),
                ),
                divider ?? _defaultDivider(context),
                if (controller.errorMessage.isNotEmpty)
                  const RecordEntryErrorBanner(),
                Expanded(
                  child: IgnorePointer(
                    ignoring: controller.isLoading,
                    child: content,
                  ),
                ),
                if (footer != null) footer!,
              ],
            ),
            Positioned(
              bottom: AppPadding.medium,
              right: AppPadding.medium,
              child: control ?? const RecordEntryFab(),
            ),
          ],
        );
      },
    );
  }

  Widget _defaultDivider(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
    );
  }
}

class RecordEntryHeader extends StatelessWidget {
  const RecordEntryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = RecordEntryProvider.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final bool isCollapsed = controller.isCollapsed;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            top: isCollapsed ? 0 : AppPadding.small,
            left: AppPadding.small,
            right: AppPadding.small,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: controller.goBack,
                  icon: Icon(
                    controller.currentIndex == 0
                        ? Icons.close
                        : Icons.arrow_back_sharp,
                    size: 24,
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: child,
                      ),
                    );
                  },
                  child: isCollapsed
                      ? Center(
                          child: Text(
                            controller.title,
                            key: const ValueKey('collapsed'),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : Column(
                          key: const ValueKey('expanded'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              controller.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (controller.subtitle != null &&
                                controller.subtitle!.isNotEmpty)
                              Text(
                                controller.subtitle!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        );
      },
    );
  }
}

class RecordEntryFab extends StatelessWidget {
  const RecordEntryFab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = RecordEntryProvider.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final Color backgroundColor = controller.isReady
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).disabledColor;
        final Color foregroundColor = controller.isReady
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8);

        return FloatingActionButton.extended(
          heroTag: 'recordEntryFab',
          onPressed: controller.onControl,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRounding.large)),
          label: controller.isLoading
              ? const ButtonLoadingIndicator()
              : Text(controller.controlLabel),
          icon: controller.isLoading
              ? null
              : Icon(controller.isSubmit ? Icons.check : Icons.arrow_forward),
        );
      },
    );
  }
}

class ComboDivider extends StatelessWidget {
  const ComboDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnimatedSize(
      duration: Durations.medium1,
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          RecordEntryQuestionProgress(),
          RecordEntryPageProgressDivider()
        ],
      ),
    );
  }
}

class RecordEntryPageProgressDivider extends StatelessWidget {
  const RecordEntryPageProgressDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = RecordEntryProvider.of(context);

    return ListenableBuilder(
      listenable: controller.pageController,
      builder: (context, _) {
        final int totalPages = controller.totalPages;

        if (totalPages <= 1) {
          return LinearProgressIndicator(
            value: 1.0,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            color: Theme.of(context).colorScheme.primary,
            minHeight: 3,
          );
        }

        double page = 0.0;
        if (controller.pageController.hasClients) {
          page = controller.pageController.page ??
              controller.currentIndex.toDouble();
        } else {
          page = controller.currentIndex.toDouble();
        }

        final double progress = (page / (totalPages - 1)).clamp(0.0, 1.0);

        return LinearProgressIndicator(
          value: progress,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          color: Theme.of(context).colorScheme.primary,
          minHeight: 3,
        );
      },
    );
  }
}

class RecordEntryQuestionProgress extends StatelessWidget {
  const RecordEntryQuestionProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = RecordEntryProvider.of(context);
    final colors = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final total = controller.totalQuestions;
        final answered = controller.answeredQuestions;
        final pendingRequired = controller.pendingRequiredCount;

        if (total == 0) {
          return const SizedBox(
            height: AppPadding.tiny,
          );
        }

        return Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$answered/$total',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: AppPadding.small),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(total, (index) {
                final bool isFilled = index < answered;
                final bool isPendingRequired =
                    !isFilled && (index - answered) < pendingRequired;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? colors.primary
                        : isPendingRequired
                            ? colors.error.withValues(alpha: 0.4)
                            : colors.surfaceContainerHighest,
                    border: isPendingRequired && !isFilled
                        ? Border.all(color: colors.error, width: 1.5)
                        : null,
                  ),
                );
              }),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: AppPadding.small),
                  if (pendingRequired > 0)
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: colors.error,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class RecordEntryErrorBanner extends StatelessWidget {
  const RecordEntryErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = RecordEntryProvider.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final message = controller.errorMessage;
        if (message.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: AppPadding.tiny, horizontal: AppPadding.small),
          decoration: BoxDecoration(
            color: colors.errorContainer,
            border: Border(
              bottom: BorderSide(
                color: colors.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colors.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: controller.dismissError,
                icon: Icon(
                  Icons.close,
                  color: colors.onErrorContainer,
                  size: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
