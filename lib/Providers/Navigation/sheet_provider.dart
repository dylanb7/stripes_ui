import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class IsSheetOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setOpen(bool value) => state = value;
}

final isSheetOpenProvider = NotifierProvider<IsSheetOpenNotifier, bool>(
  IsSheetOpenNotifier.new,
);

final Provider<ScrollController> historyScrollControllerProvider =
    Provider<ScrollController>((ref) {
      final ScrollController controller = ScrollController();
      ref.onDispose(controller.dispose);
      return controller;
    });

// Tab routes can recreate EventsView. Keep its scroll and entry expansion
// storage in the same scope as its controller so returning restores both.
final historyPageStorageProvider = Provider<PageStorageBucket>(
  (ref) => PageStorageBucket(),
);

class HistoryCalendarNavNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setVisible(bool value) {
    if (state != value) state = value;
  }

  void hide() => setVisible(false);
}

/// Whether History's compact date navigator should float above the tab bar.
final historyCalendarNavVisibleProvider =
    NotifierProvider<HistoryCalendarNavNotifier, bool>(
      HistoryCalendarNavNotifier.new,
    );

final sheetControllerProvider = Provider<SheetController>((ref) {
  return SheetController(ref);
});

typedef DraggableSheetBuilder = Widget Function(BuildContext, ScrollController);

typedef ChildBuilder = Widget Function(BuildContext);

class SheetController {
  final Ref ref;

  SheetController(this.ref);

  Future<T?> show<T>({
    required BuildContext context,
    ChildBuilder? child,
    bool scrollControlled = false,
    ShapeBorder? dialogShape,
    ShapeBorder? bottomSheetShape,
    DraggableSheetBuilder? sheetBuilder,
    double elevation = 2.0,
    bool safeArea = true,
    bool avoidKeyboard = false,
    double initialChildSize = 0.55,
    double maxChildSize = 0.9,
    List<double>? snapSizes,
  }) {
    assert(child != null || sheetBuilder != null);
    final double height = MediaQuery.of(context).size.height;

    bool isFullScreen = height < Breakpoint.small.value;

    final Color backgroundColor = Theme.of(context).colorScheme.surface;

    final bool showingDialog =
        getBreakpoint(context).isGreaterThan(Breakpoint.large) || isFullScreen;

    ref.read(isSheetOpenProvider.notifier).setOpen(true);

    if (showingDialog) {
      final ShapeBorder finalDialogShape =
          dialogShape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(
              Radius.circular(AppRounding.tiny),
            ),
          );
      return showDialog<T>(
        context: context,
        useSafeArea: safeArea,
        fullscreenDialog: isFullScreen,
        builder: (context) {
          final content = child != null
              ? child(context)
              : sheetBuilder!(context, ScrollController());
          if (isFullScreen) {
            // fullscreenDialog changes the route transition, not Dialog's
            // default insets. Use the full viewport on short phone screens.
            return Dialog.fullscreen(
              backgroundColor: backgroundColor,
              child: content,
            );
          }
          return Dialog(
            constraints: BoxConstraints(
              maxWidth: Breakpoint.medium.value,
              minWidth: 280.0,
              maxHeight: scrollControlled || sheetBuilder != null
                  ? height * 0.8
                  : double.infinity,
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppPadding.xl,
              vertical: AppPadding.large,
            ),
            backgroundColor: backgroundColor,
            shape: finalDialogShape,
            alignment: Alignment.center,
            elevation: elevation,
            child: content,
          );
        },
      ).whenComplete(() {
        ref.read(isSheetOpenProvider.notifier).setOpen(false);
      });
    }

    final bool draggableScrollableSheet = sheetBuilder != null;

    final ShapeBorder finalBottomSheetShape =
        bottomSheetShape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.all(Radius.zero),
        );

    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: safeArea,
      shape: finalBottomSheetShape,
      isScrollControlled: scrollControlled,
      elevation: elevation,
      backgroundColor: backgroundColor,
      builder: (context) {
        final Widget content;
        if (draggableScrollableSheet) {
          content = DraggableScrollableSheet(
            expand: false,
            initialChildSize: initialChildSize,
            minChildSize: 0.4,
            maxChildSize: maxChildSize,
            snapSizes: snapSizes ?? [initialChildSize, maxChildSize],
            snap: true,
            builder: sheetBuilder,
          );
        } else {
          content = child!(context);
        }
        return avoidKeyboard
            ? Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: content,
              )
            : content;
      },
    ).whenComplete(() {
      ref.read(isSheetOpenProvider.notifier).setOpen(false);
    });
  }
}
