import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/palette.dart';

class Expandible extends StatefulWidget {
  final Widget header;

  final Widget view;

  final bool canExpand;

  final bool hasIndicator;

  final bool selected;

  final bool highlightOnShrink;

  final Color highlightColor;

  final ExpandibleListener? listener;

  const Expandible(
      {required this.header,
      required this.view,
      this.canExpand = true,
      this.selected = false,
      this.hasIndicator = true,
      this.highlightOnShrink = false,
      this.highlightColor = buttonDarkBackground,
      this.listener,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ExpandibleState();
  }
}

class _ExpandibleState extends State<Expandible>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;

  late Animation<double> _heightFactor;

  late bool _expanded, _canExpand;

  late ExpandibleListener _listener;

  @override
  void initState() {
    _expandController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
        reverseDuration: const Duration(milliseconds: 500));
    _heightFactor = _expandController.drive(CurveTween(curve: Curves.easeIn));
    _canExpand = widget.canExpand;
    _expanded = !_canExpand;
    _listener = widget.listener ?? ExpandibleListener();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _listener.expanded.value = _expanded;
      if (_expanded) {
        _expandController.value = _expandController.upperBound;
      }
    });
    _listener.expanded.addListener(() {
      if (!_canExpand) return;
      _expanded = _listener.expanded.value;
      if (_expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse().then<void>((void value) {
          if (!mounted) return;
          setState(() {});
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _expandController.view,
        child: _expanded
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: widget.view,
              )
            : null,
        builder: (context, poss) {
          return GestureDetector(
            onTap: () {
              if (!_canExpand) return;
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
                _listener.expanded.value = _expanded;
              });
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                  side: (_expanded || widget.highlightOnShrink) &&
                          widget.selected
                      ? BorderSide(color: widget.highlightColor, width: 5.0)
                      : const BorderSide(width: 0, color: Colors.transparent)),
              color: darkBackgroundText,
              elevation: 7.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: 8.0,
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(child: widget.header),
                          if (_canExpand && widget.hasIndicator) ...[
                            const SizedBox(
                              width: 4.0,
                            ),
                            Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              color: darkIconButton,
                            )
                          ],
                          const SizedBox(
                            width: 4.0,
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 8.0,
                      ),
                      ClipRect(
                        child: Align(
                          alignment: Alignment.topLeft,
                          heightFactor: _heightFactor.value,
                          child: poss,
                        ),
                      ),
                    ]),
              ),
            ),
          );
        });
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }
}

class ExpandibleListener {
  ValueNotifier<bool> expanded = ValueNotifier(false);
}
