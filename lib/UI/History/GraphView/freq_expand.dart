import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/styled_tooltip.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';

class FreqExpandible extends StatefulWidget {
  final Widget header, view;

  const FreqExpandible({required this.header, required this.view, super.key});

  @override
  State<StatefulWidget> createState() => _FreqExpandState();
}

class _FreqExpandState extends State<FreqExpandible>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;

  late Animation<double> _heightFactor;

  late bool _expanded;

  @override
  void initState() {
    _expanded = false;
    _expandController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
        reverseDuration: const Duration(milliseconds: 500));
    _heightFactor = _expandController.drive(CurveTween(curve: Curves.easeIn));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _expandController.view,
        child: _expanded
            ? Padding(
                padding: const EdgeInsets.all(4.0),
                child: widget.view,
              )
            : null,
        builder: (context, poss) {
          return GestureDetector(
            onTap: () {
              setState(() {
                if (_expandController.isAnimating) return;
                _expanded = !_expanded;
                if (_expanded) {
                  _expandController.forward();
                } else {
                  _expandController.reverse().then<void>((void value) {
                    if (!mounted) return;
                    setState(() {});
                  });
                }
              });
            },
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(child: widget.header),
                      const SizedBox(
                        width: 4.0,
                      ),
                      StyledTooltip(
                        message: 'Common Behaviors',
                        child: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                        ),
                      ),
                      const SizedBox(
                        width: 4.0,
                      )
                    ],
                  ).showCursorOnHover,
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topLeft,
                      heightFactor: _heightFactor.value,
                      child: poss,
                    ),
                  ),
                ]),
          );
        });
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }
}
