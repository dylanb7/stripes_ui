import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_ui/UI/CommonWidgets/tonal_button.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class ConfirmationPopup extends ConsumerWidget {
  final String confirm;

  final String cancel;

  final Function? onConfirm;
  final Function? onCancel;

  final Widget title;

  final Widget body;

  const ConfirmationPopup(
      {required this.title,
      required this.body,
      required this.cancel,
      required this.confirm,
      this.onConfirm,
      this.onCancel,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.small, vertical: AppPadding.medium),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
            child: Card(
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppRounding.small))),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
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
                          width: AppPadding.xxl,
                        ),
                        title,
                        IconButton(
                          onPressed: () {
                            onCancel?.call();
                            Navigator.of(context).pop(false);
                          },
                          icon: const Icon(Icons.close),
                          iconSize: 35,
                        )
                      ],
                    ),
                    const SizedBox(
                      height: AppPadding.small,
                    ),
                    body,
                    const SizedBox(
                      height: AppPadding.large,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        FilledButton(
                            onPressed: () {
                              onCancel?.call();
                              Navigator.of(context).pop(false);
                            },
                            child: Text(cancel)),
                        TonalButtonTheme(
                          child: FilledButton.tonal(
                            onPressed: () {
                              _confirm(context);
                            },
                            child: Text(confirm),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _confirm(BuildContext context) {
    if (onConfirm != null) onConfirm!();
    Navigator.of(context).pop(true);
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
      super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        onClick(context);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        shape: WidgetStateProperty.all(const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(AppRounding.small)))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppPadding.tiny, horizontal: AppPadding.small),
        child: Text(
          text,
          style:
              Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20),
        ),
      ),
    );
  }
}
