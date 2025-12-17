import 'dart:math';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class FormContainer extends StatefulWidget {
  static const duration = Duration(milliseconds: 200);

  final bool animated, hasClose;

  final Widget topPortion;

  final Widget form;

  final Widget? bottomPortion;

  final Function? close;

  const FormContainer(
      {required this.topPortion,
      required this.form,
      this.bottomPortion,
      this.hasClose = true,
      this.animated = true,
      this.close,
      super.key});

  @override
  State createState() => _FormContainerState();
}

class _FormContainerState extends State<FormContainer>
    with SingleTickerProviderStateMixin {
  bool present = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        present = true;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;

    final double blueHeight = max(height * 0.3, 160);
    final double middlesTop = blueHeight - 35;

    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: FormContainer.duration,
            left: 0,
            right: 0,
            top: present ? 0 : -blueHeight,
            height: blueHeight,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.darken())),
          ),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: middlesTop,
                      child: Stack(
                        children: [
                          Center(
                            child: widget.topPortion,
                          ),
                          if (widget.hasClose)
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: AppPadding.small,
                                    left: AppPadding.small),
                                child: IconButton(
                                  iconSize: 35,
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                  ),
                                  onPressed: () {
                                    (widget.close ??
                                        () {
                                          Navigator.of(context).pop();
                                        })();
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.large),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 600,
                        ),
                        child: Card(
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12.0)),
                          ),
                          elevation: 1.0,
                          child: widget.form,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (widget.bottomPortion != null) widget.bottomPortion!,
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
