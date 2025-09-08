import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/paddings.dart';

typedef DraggableSheetBuilder = Widget Function(BuildContext, ScrollController);

typedef ChildBuilder = Widget Function(BuildContext);
//if scroll controller is specified use draggableScrollableSheet
Future<T?> showStripesSheet<T>({
  required BuildContext context,
  ChildBuilder? child,
  bool scrollControlled = false,
  ShapeBorder? dialogShape,
  ShapeBorder? bottomSheetShape,
  DraggableSheetBuilder? sheetBuilder,
  double elevation = 2.0,
  bool safeArea = true,
}) {
  assert(child != null || sheetBuilder != null);
  final double height = MediaQuery.of(context).size.height;

  bool isFullScreen = height < Breakpoint.small.value;

  final Color backgroundColor = Theme.of(context).colorScheme.surface;

  final bool showingDialog =
      getBreakpoint(context).isGreaterThan(Breakpoint.large) || isFullScreen;

  if (showingDialog) {
    final ShapeBorder finalDialogShape = dialogShape ??
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
          return Dialog(
            constraints: isFullScreen
                ? null
                : BoxConstraints(
                    maxWidth: Breakpoint.medium.value,
                    minWidth: 280.0,
                    maxHeight: (scrollControlled || sheetBuilder != null) &&
                            !isFullScreen
                        ? height * 0.8
                        : double.infinity),
            insetPadding: isFullScreen
                ? null
                : const EdgeInsets.symmetric(
                    horizontal: AppPadding.xl, vertical: AppPadding.large),
            backgroundColor: backgroundColor,
            shape: finalDialogShape,
            alignment: Alignment.center,
            elevation: elevation,
            child: child != null
                ? child(context)
                : sheetBuilder!(context, ScrollController()),
          );
        });
  }

  final bool draggableScrollableSheet = sheetBuilder != null;

  final ShapeBorder finalBottomSheetShape = bottomSheetShape ??
      const RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.all(Radius.zero));

  return showModalBottomSheet<T>(
      context: context,
      useSafeArea: safeArea,
      shape: finalBottomSheetShape,
      isScrollControlled: scrollControlled,
      elevation: elevation,
      backgroundColor: backgroundColor,
      builder: (context) {
        if (draggableScrollableSheet) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            maxChildSize: 0.9,
            snapSizes: const [0.55, 0.9],
            snap: true,
            builder: sheetBuilder,
          );
        }
        return child!(context);
      });
}
