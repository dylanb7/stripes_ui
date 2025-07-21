import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/expand_collapse_icon.dart';

enum NotificationType { info, error }

// To be used within a stack
class AccountNotification extends ConsumerStatefulWidget {
  final Widget content;
  final Widget collapsedContent;
  final NotificationType notificationType;
  final Curve curve;
  final Duration duration;

  const AccountNotification(
      {required this.content,
      required this.collapsedContent,
      this.notificationType = NotificationType.info,
      this.curve = Curves.easeInOut,
      this.duration = Durations.medium1,
      super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return InvitedIndicatorState();
  }
}

class InvitedIndicatorState extends ConsumerState<AccountNotification>
    with RestorationMixin {
  bool updating = false;

  RestorableBool collapsed = RestorableBool(false);

  @override
  void dispose() {
    collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = getBreakpoint(context).isLessThan(Breakpoint.small);
    final bool shrinks = !isSmall && !collapsed.value;

    const collapsedIconSize = 24.0, fullIconSize = 36.0;

    Widget statusIcon = AnimatedSize(
      duration: widget.duration,
      curve: widget.curve,
      child: Stack(
        children: [
          Container(
            width: collapsed.value ? collapsedIconSize : fullIconSize,
            height: collapsed.value ? collapsedIconSize : fullIconSize,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface),
          ),
          Icon(
            Icons.info_outlined,
            color: widget.notificationType == NotificationType.error
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.secondary,
            size: collapsed.value ? collapsedIconSize : fullIconSize,
          ),
        ],
      ),
    );

    Border? containerBorder = shrinks
        ? Border.all(color: Theme.of(context).primaryColor, width: 1.5)
        : collapsed.value
            ? Border(
                top: BorderSide(
                    color: Theme.of(context).primaryColor, width: 1.5),
              )
            : null;

    Widget iconRow = Row(
      crossAxisAlignment:
          isSmall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (isSmall && !collapsed.value) const Spacer(),
        Expanded(
          child: AnimatedAlign(
            alignment:
                collapsed.value ? Alignment.centerLeft : Alignment.center,
            duration: widget.duration,
            curve: widget.curve,
            child: statusIcon,
          ),
        ),
        if (shrinks) Expanded(flex: 4, child: widget.content),
        if (collapsed.value) Expanded(flex: 4, child: widget.collapsedContent),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: collapsed.value ? collapsedIconSize : fullIconSize,
              height: collapsed.value ? collapsedIconSize : fullIconSize,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor),
              child: ExpandCollapseIcon(
                duration: widget.duration,
                curve: widget.curve,
                padding: EdgeInsets.zero,
                isExpanded: collapsed.value,
                size: collapsed.value ? collapsedIconSize : fullIconSize,
                color: Theme.of(context).colorScheme.surface,
                onPressed: (expanded) {
                  setState(() {
                    collapsed.value = !expanded;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );

    return AnimatedPositioned(
      duration: Durations.medium1,
      curve: Curves.easeInOut,
      bottom: collapsed.value ? 0.0 : 16.0,
      left: isSmall ? 0.0 : 16.0,
      right: isSmall ? 0.0 : 16.0,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: shrinks ? double.maxFinite : Breakpoint.small.value),
          child: AnimatedContainer(
            decoration: BoxDecoration(
              border: containerBorder,
              borderRadius:
                  shrinks ? BorderRadius.circular(12.0) : BorderRadius.zero,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            ),
            duration: Durations.medium1,
            curve: Curves.easeInOut,
            child: ClipRRect(
              borderRadius:
                  shrinks ? BorderRadius.circular(12.0) : BorderRadius.zero,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 8.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        iconRow,
                        if (isSmall && !collapsed.value) widget.content
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  String? get restorationId => "indicator_collapsed_restoration";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(collapsed, 'indicator_collapsed');
  }
}
