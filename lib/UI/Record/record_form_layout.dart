import 'package:flutter/widgets.dart';

/// Keeps record headers, forms, and actions on the same readable column while
/// allowing the surrounding surfaces to span a tablet or desktop window.
class RecordFormLayout extends StatelessWidget {
  static const double maxWidth = 800;
  static const double horizontalPadding = 24;

  final Widget child;
  final EdgeInsetsGeometry padding;

  const RecordFormLayout({
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        width: double.infinity,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}
