import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/entry.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSnack(
    BuildContext context, String message,
    {Function? action, String? actionMessage, Color? accentColor}) {
  if (!context.mounted) return null;

  // Use root ScaffoldMessenger if available, otherwise fall back to context
  final messenger =
      rootScaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);

  return messenger.showSnackBar(
    SnackBar(
      padding: EdgeInsets.zero,
      content: _TimerContent(
        message: message,
        action: action,
        actionMessage: actionMessage,
        accentColor: accentColor,
      ),
      duration: const Duration(seconds: 4),
      dismissDirection: DismissDirection.down,
      behavior: SnackBarBehavior.floating,
      showCloseIcon: false,
      margin: const EdgeInsets.only(
          left: AppPadding.tiny,
          right: AppPadding.tiny,
          bottom: AppPadding.tiny),
    ),
  );
}

class _TimerContent extends StatefulWidget {
  final String message;
  final Function? action;
  final String? actionMessage;
  final Color? accentColor;

  const _TimerContent(
      {required this.message,
      this.action,
      this.actionMessage,
      this.accentColor});

  @override
  State<_TimerContent> createState() => _TimerContentState();
}

class _TimerContentState extends State<_TimerContent>
    with SingleTickerProviderStateMixin {
  late AnimationController conversionController;

  @override
  void initState() {
    super.initState();
    conversionController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000));
    conversionController.forward();
  }

  @override
  void dispose() {
    conversionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color? accent = widget.accentColor;
    final Color progressColor = accent ?? Theme.of(context).colorScheme.inversePrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.large, vertical: AppPadding.medium),
          child: Row(
            children: [
              if (accent != null) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: AppPadding.small),
              ],
              Expanded(
                child: Text(
                  widget.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onInverseSurface),
                ),
              ),
              if (widget.action != null) ...[
                const SizedBox(
                  width: AppPadding.small,
                ),
                TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      widget.action!();
                    },
                    child: Text(widget.actionMessage ?? context.translate.undo))
              ]
            ],
          ),
        ),
        AnimatedBuilder(
          animation: conversionController,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: conversionController.value,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 4.0,
            );
          },
        ),
      ],
    );
  }
}
