import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class ConfirmationPopup extends ConsumerWidget {
  final String confirm;

  final String cancel;

  final Function? onConfirm;

  final Widget children;

  const ConfirmationPopup(
      {required this.children,
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
            color: lightBackgroundText.withOpacity(0.9),
          ),
        ),
        Center(
          child: SizedBox(
            width: SMALL_LAYOUT / 1.7,
            child: Card(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0))),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    children,
                    const SizedBox(
                      height: 8.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        BasicButton(
                            onClick: (context) {
                              _dismiss(context, ref);
                            },
                            color: buttonDarkBackground,
                            text: cancel),
                        BasicButton(
                            onClick: (context) {
                              _confirm(context, ref);
                            },
                            color: buttonDarkBackground,
                            text: confirm),
                      ],
                    ),
                  ],
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
            borderRadius: BorderRadius.all(Radius.circular(15)))),
      ),
      child: Text(
        text,
        style: darkBackgroundStyle,
      ),
    );
  }
}
