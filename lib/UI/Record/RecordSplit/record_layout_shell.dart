import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/animated_segmented_progress.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/UI/CommonWidgets/category_chip.dart';
import 'package:stripes_ui/UI/Record/record_form_layout.dart';
import 'package:stripes_ui/Util/extensions.dart';

class RecordEntryController extends ChangeNotifier {
  String _title;
  String? _subtitle;
  int _currentIndex;
  int _totalPages;
  List<String> _pageIds;
  PageController _pageController;
  VoidCallback _onClose;
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
  bool _validationFailed;
  IconData? _icon;
  CategoryAppearance? _categoryAppearance;
  Color? _color;
  String? _categoryTitle;

  RecordEntryController({
    required String title,
    String? subtitle,
    IconData? icon,
    CategoryAppearance? categoryAppearance,
    Color? color,
    String? categoryTitle,
    required int currentIndex,
    required int totalPages,
    List<String>? pageIds,
    required PageController pageController,
    required VoidCallback onClose,
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
    bool validationFailed = false,
  }) : _title = title,
       _subtitle = subtitle,
       _icon = icon,
       _categoryAppearance = categoryAppearance,
       _color = color,
       _categoryTitle = categoryTitle,
       _currentIndex = currentIndex,
       _totalPages = totalPages,
       _pageIds = _normalizePageIds(pageIds, totalPages),
       _pageController = pageController,
       _onClose = onClose,
       _isLoading = isLoading,
       _onControl = onControl,
       _controlLabel = controlLabel,
       _isReady = isReady,
       _isSubmit = isSubmit,
       _errorMessage = errorMessage,
       _onDismissError = onDismissError,
       _totalQuestions = totalQuestions,
       _answeredQuestions = answeredQuestions,
       _pendingRequiredCount = pendingRequiredCount,
       _validationFailed = validationFailed;

  static List<String> _normalizePageIds(List<String>? pageIds, int totalPages) {
    if (pageIds != null && pageIds.length == totalPages) {
      return List.unmodifiable(pageIds);
    }
    return List.unmodifiable(
      List.generate(totalPages, (index) => 'record-page-$index'),
    );
  }

  String get title => _title;
  String? get subtitle => _subtitle;
  IconData? get icon => _icon;
  CategoryAppearance? get categoryAppearance => _categoryAppearance;
  Color? get color => _color;
  String? get categoryTitle => _categoryTitle;
  int get currentIndex => _currentIndex;
  int get totalPages => _totalPages;
  List<String> get pageIds => _pageIds;
  PageController get pageController => _pageController;
  VoidCallback get onClose => _onClose;
  bool get isLoading => _isLoading;
  VoidCallback? get onControl => _onControl;
  String get controlLabel => _controlLabel;
  bool get isReady => _isReady;
  bool get isSubmit => _isSubmit;
  String get errorMessage => _errorMessage ?? '';
  int get totalQuestions => _totalQuestions;
  int get answeredQuestions => _answeredQuestions;
  int get pendingRequiredCount => _pendingRequiredCount;
  bool get validationFailed => _validationFailed;

  void update({
    String? title,
    String? subtitle,
    IconData? icon,
    CategoryAppearance? categoryAppearance,
    Color? color,
    String? categoryTitle,
    int? currentIndex,
    int? totalPages,
    List<String>? pageIds,
    bool? isLoading,
    VoidCallback? onControl,
    String? controlLabel,
    bool? isReady,
    bool? isSubmit,
    String? errorMessage,
    int? totalQuestions,
    int? answeredQuestions,
    int? pendingRequiredCount,
    bool? validationFailed,
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
    if (icon != null && _icon != icon) {
      _icon = icon;
      changed = true;
    }
    if (categoryAppearance != null &&
        _categoryAppearance != categoryAppearance) {
      _categoryAppearance = categoryAppearance;
      changed = true;
    }
    if (color != null && _color != color) {
      _color = color;
      changed = true;
    }
    if (categoryTitle != null && _categoryTitle != categoryTitle) {
      _categoryTitle = categoryTitle;
      changed = true;
    }
    if (currentIndex != null && _currentIndex != currentIndex) {
      _currentIndex = currentIndex;
      changed = true;
    }
    if (totalPages != null && _totalPages != totalPages) {
      _totalPages = totalPages;
      _pageIds = _normalizePageIds(pageIds, totalPages);
      changed = true;
    } else if (pageIds != null && !_samePageIds(_pageIds, pageIds)) {
      _pageIds = _normalizePageIds(pageIds, _totalPages);
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
    if (validationFailed != null && _validationFailed != validationFailed) {
      _validationFailed = validationFailed;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  static bool _samePageIds(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
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
    final provider = context
        .dependOnInheritedWidgetOfExactType<RecordEntryProvider>();
    assert(provider != null, 'No RecordEntryProvider found in context');
    return provider!.notifier!;
  }

  static RecordEntryController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RecordEntryProvider>()
        ?.notifier;
  }
}

/// Control style for RecordEntryShell
enum RecordControlStyle {
  /// Floating action button positioned in bottom-right
  fab,

  /// Full-width bottom bar docked at bottom
  bottomBar,
}

class RecordEntryShell extends StatelessWidget {
  final Widget content;
  final Widget? header;
  final Widget? divider;
  final Widget? control;
  final Widget? footer;
  final RecordControlStyle controlStyle;
  final bool alignContent;

  const RecordEntryShell({
    super.key,
    required this.content,
    this.header,
    this.divider,
    this.control,
    this.footer,
    this.controlStyle = RecordControlStyle.fab,
    this.alignContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = RecordEntryProvider.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final Widget effectiveControl =
            control ??
            (controlStyle == RecordControlStyle.bottomBar
                ? RecordEntryBottomBar(alignContent: alignContent)
                : const RecordEntryFab());

        final bool isBottomBar = controlStyle == RecordControlStyle.bottomBar;

        return Stack(
          children: [
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: _alignContent(header ?? const RecordEntryHeader()),
                ),
                _alignContent(divider ?? _defaultDivider(context)),
                if (controller.errorMessage.isNotEmpty)
                  _alignContent(const RecordEntryErrorBanner()),
                Expanded(
                  child: IgnorePointer(
                    ignoring: controller.isLoading,
                    child: _alignContent(content),
                  ),
                ),
                if (footer != null) _alignContent(footer!),
                if (isBottomBar) effectiveControl,
              ],
            ),
            if (!isBottomBar)
              Positioned(
                bottom: AppPadding.medium,
                right: AppPadding.medium,
                child: effectiveControl,
              ),
          ],
        );
      },
    );
  }

  Widget _alignContent(Widget child) =>
      alignContent ? RecordFormLayout(child: child) : child;

  Widget _defaultDivider(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
    );
  }
}

class RecordEntryHeader extends StatelessWidget {
  const RecordEntryHeader({this.showNavigation = true, super.key});

  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final controller = RecordEntryProvider.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final String fullTitle = controller.title;
        final String? category = controller.categoryTitle;

        List<Widget> buildTitleWidgets() {
          if (category == null || !fullTitle.contains(category)) {
            return [
              Text(
                fullTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ];
          }

          final parts = fullTitle.split(category);
          final prefix = parts[0];
          final suffix = parts.sublist(1).join(category);

          return [
            // The compact navigation header already says "Record" when this
            // context is inside the scroll view.
            if (showNavigation && prefix.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: AppPadding.tiny),
                child: Text(
                  prefix.trim(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            if (controller.categoryAppearance != null ||
                controller.color != null)
              CategoryChip(
                useColor: controller.color != null,
                appearance:
                    controller.categoryAppearance ??
                    CategoryAppearance(
                      color: controller.color!,
                      icon: controller.icon ?? Icons.question_mark,
                    ),
                categoryName: category,
                iconSize: 18.0,
              )
            else
              Text(
                category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            if (showNavigation && suffix.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: AppPadding.tiny),
                child: Text(
                  suffix.trim(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ];
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.small,
            vertical: AppPadding.tiny,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showNavigation) const _RecordEntryBackButton(),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...buildTitleWidgets(),
                      if (controller.subtitle != null &&
                          controller.subtitle!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.tiny,
                          ),
                          child: Text(
                            '·',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          controller.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (showNavigation) const SizedBox(width: 48),
            ],
          ),
        );
      },
    );
  }
}

/// Keeps navigation reachable when the full context header scrolls with a
/// form on a short screen or at a large reading size.
class RecordEntryNavigationHeader extends StatelessWidget {
  const RecordEntryNavigationHeader({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const _RecordEntryBackButton(),
      Expanded(
        child: Text(
          context.translate.recordTab,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      const SizedBox(width: 48),
    ],
  );
}

class _RecordEntryBackButton extends StatelessWidget {
  const _RecordEntryBackButton();

  @override
  Widget build(BuildContext context) {
    final controller = RecordEntryProvider.of(context);
    final firstPage = controller.currentIndex == 0;
    return IconButton(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      tooltip: firstPage
          ? MaterialLocalizations.of(context).closeButtonTooltip
          : MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: controller.goBack,
      icon: Icon(firstPage ? Icons.close : Icons.arrow_back_sharp),
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
            borderRadius: BorderRadius.circular(AppRounding.large),
          ),
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

/// A bottom bar control styled like DateRangeSelector.
/// Can be used as an alternative to RecordEntryFab by passing it as `control` to RecordEntryShell.
class RecordEntryBottomBar extends StatelessWidget {
  final bool alignContent;

  const RecordEntryBottomBar({this.alignContent = false, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = RecordEntryProvider.of(context);
    final colors = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final bool isReady = controller.isReady;
        final bool isLoading = controller.isLoading;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: _alignContent(
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: alignContent
                      ? RecordFormLayout.horizontalPadding
                      : AppPadding.medium,
                  vertical: AppPadding.small,
                ),
                child: Row(
                  children: [
                    // Next/Submit button - expanded to fill width
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isLoading ? null : controller.onControl,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppPadding.medium,
                            horizontal: AppPadding.large,
                          ),
                          backgroundColor: isReady
                              ? colors.primary
                              : colors.surfaceContainerHigh,
                          foregroundColor: isReady
                              ? colors.onPrimary
                              : colors.onSurface.withValues(alpha: 0.6),
                        ),
                        icon: isLoading
                            ? const ButtonLoadingIndicator()
                            : Icon(
                                controller.isSubmit
                                    ? Icons.check
                                    : Icons.arrow_forward,
                                size: 18,
                              ),
                        label: Text(controller.controlLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _alignContent(Widget child) =>
      alignContent ? RecordFormLayout(child: child) : child;
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
          RecordEntryPageProgressDivider(),
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
      listenable: controller,
      builder: (context, _) {
        return AnimatedSegmentedProgress(
          segmentIds: controller.pageIds,
          currentIndex: controller.currentIndex,
          currentHasError: controller.validationFailed,
          pageController: controller.pageController,
          semanticsKey: const ValueKey('record-entry-page-progress'),
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
          return const SizedBox(height: AppPadding.tiny);
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

        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: message.isEmpty
              ? const SizedBox(width: double.infinity, height: 0)
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppPadding.tiny,
                    horizontal: AppPadding.small,
                  ),
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
                ),
        );
      },
    );
  }
}
