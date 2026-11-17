import 'package:flutter/material.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_progress.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_study_style.dart';
import 'package:stripes_ui/Util/Widgets/floating_nav_bar.dart';
import 'package:stripes_ui/Util/extensions.dart';

class BlueDyeStudyLayout extends StatelessWidget {
  final BlueDyeProgression progression;
  final Widget child;
  const BlueDyeStudyLayout({
    required this.progression,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.translate;
    final subtitle = switch (progression) {
      BlueDyeProgression.stepOne ||
      BlueDyeProgression.stepTwo => s.transitOneLabel,
      BlueDyeProgression.stepThree => s.blueMealWaitTimeLabel,
      BlueDyeProgression.stepFour ||
      BlueDyeProgression.stepFive => s.transitTwoLabel,
      BlueDyeProgression.completed => s.blueMealStudyCompleteTitle,
    };
    return ColoredBox(
      color: BlueDyeStudyStyle.canvas(context),
      child: RefreshWidget(
        depth: RefreshDepth.authuser,
        scrollable: SingleChildScrollView(
          key: const PageStorageKey('blue-meal-redesign-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(
                    color: BlueDyeStudyStyle.surface(context),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          BlueDyeStudyHeader(subtitle: subtitle),
                          const SizedBox(height: 20),
                          BlueDyeStudyProgress(progression: progression),
                        ],
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.all(20), child: child),
                  SizedBox(
                    height: 24 + FloatingNavBarScope.bottomPaddingOf(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
