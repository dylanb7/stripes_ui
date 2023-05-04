import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/palette.dart';

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
      Key? key})
      : super(key: key);

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

    return Stack(
      children: [
        AnimatedPositioned(
          duration: FormContainer.duration,
          left: 0,
          right: 0,
          top: present ? 0 : -blueHeight,
          height: blueHeight,
          child: const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [backgroundStrong, backgroundLight])),
          ),
        ),
        const Positioned.fill(child: ColoredBox(color: Colors.white)),
        Positioned.fill(
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
                          alignment: Alignment.topRight,
                          child: IconButton(
                            iconSize: 35,
                            icon: const Icon(
                              Icons.close,
                              color: darkBackgroundText,
                            ),
                            onPressed: () {
                              (widget.close ??
                                  () {
                                    Navigator.of(context).pop();
                                  })();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: Card(
                      color: darkBackgroundText,
                      shadowColor: backgroundLight,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      ),
                      elevation: 8.0,
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
      ],
    );
  }
}
