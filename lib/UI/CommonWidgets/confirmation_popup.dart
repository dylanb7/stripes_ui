import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class ConfirmationPopup extends ConsumerWidget {
  final String confirm;

  final String cancel;

  final Function? onConfirm;

  final Widget title;

  final Widget body;

  const ConfirmationPopup(
      {required this.title,
      required this.body,
      required this.cancel,
      required this.confirm,
      this.onConfirm,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.9),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Center(
            child: SizedBox(
              width: SMALL_LAYOUT / 1.7,
              child: Card(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 35,
                          ),
                          title,
                          IconButton(
                            onPressed: () {
                              _dismiss(context, ref);
                            },
                            icon: const Icon(Icons.close),
                            iconSize: 35,
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      body,
                      const SizedBox(
                        height: 16.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          FilledButton(
                              onPressed: () {
                                _dismiss(context, ref);
                              },
                              child: Text(cancel)),
                          FilledButton.tonal(
                              onPressed: () {
                                _confirm(context, ref);
                              },
                              child: Text(confirm))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _dismiss(BuildContext context, WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = closedQuery;
  }

  _confirm(BuildContext context, WidgetRef ref) {
    if (onConfirm != null) onConfirm!();
    _dismiss(context, ref);
  }
}

class BasicButton extends StatelessWidget {
  final Function(BuildContext) onClick;

  final String text;

  final Color color;

  const BasicButton(
      {required this.onClick,
      required this.color,
      required this.text,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        onClick(context);
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(color),
        shape: MaterialStateProperty.all(const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
        child: Text(
          text,
          style: darkBackgroundHeaderStyle.copyWith(fontSize: 20),
        ),
      ),
    );
  }
}
