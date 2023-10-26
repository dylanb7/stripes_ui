import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class OverlayQuery {
  final Widget? widget;
  const OverlayQuery({this.widget});
}

const closedQuery = OverlayQuery();

class OverlayBackdrop extends ConsumerWidget {
  final Widget child;

  final bool dismissOnBackdropTouch;

  const OverlayBackdrop(
      {required this.child, this.dismissOnBackdropTouch = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: () {
            if (dismissOnBackdropTouch) {
              ref.read(overlayProvider.notifier).state = closedQuery;
            }
          },
          child: ColoredBox(
            color: Colors.black.withOpacity(0.9),
          ),
        ),
      ),
      Center(
        child: child,
      )
    ]);
  }
}

final overlayProvider =
    StateProvider.autoDispose<OverlayQuery>((_) => closedQuery);
