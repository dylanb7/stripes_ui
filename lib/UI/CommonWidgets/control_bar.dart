import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/AppStyleHelpers/app_surface.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class ControlBar extends StatelessWidget {
  final List<Widget> children;

  const ControlBar({required this.children, super.key});

  @override
  Widget build(BuildContext context) => AppSurface(
    level: SurfaceLevel.flat,
    rounding: AppRounding.large,
    elevation: 12,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: AppPadding.tiny,
      ),
      child: Row(children: children),
    ),
  );
}
