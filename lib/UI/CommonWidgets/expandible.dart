import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/CommonWidgets/styled_tooltip.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/Util/paddings.dart';

class Expandible extends StatefulWidget {
  final Widget header;

  final Widget view;

  final bool canExpand;

  final bool hasIndicator;

  final bool highlightOnShrink;

  final bool elevated;

  final Color? highlightColor;

  final double? iconSize, highlightWidth;

  final ExpandibleController? listener;

  const Expandible(
      {required this.header,
      required this.view,
      this.canExpand = true,
      this.hasIndicator = true,
      this.highlightOnShrink = false,
      this.elevated = true,
      this.iconSize,
      this.highlightColor,
      this.highlightWidth,
      this.listener,
      super.key});

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

  late ExpandibleController _controller;

  @override
  void initState() {
    _expandController = AnimationController(
        duration: const Duration(milliseconds: 350),
        vsync: this,
        reverseDuration: const Duration(milliseconds: 350));
    _heightFactor = _expandController.drive(CurveTween(curve: Curves.easeIn));
    _canExpand = widget.canExpand;
    _expanded = !_canExpand;
    _controller = widget.listener ?? ExpandibleController(_expanded);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.set(_expanded);
      if (_expanded) {
        _expandController.value = _expandController.upperBound;
      }
    });
    _controller.addListener(() {
      if (!_canExpand || !mounted) return;
      _expanded = _controller.expanded;
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
        child: _expanded ? widget.view : null,
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
                _controller.set(_expanded);
              });
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                  side: (_expanded || widget.highlightOnShrink) &&
                          widget.highlightColor != null
                      ? BorderSide(
                          color: widget.highlightColor!,
                          width: widget.highlightWidth ?? 4.0)
                      : const BorderSide(width: 0, color: Colors.transparent)),
              elevation: widget.elevated ? 1.0 : 0.0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppPadding.tiny),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: AppPadding.tiny,
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: AppPadding.small,
                          ),
                          Expanded(child: widget.header),
                          if (_canExpand && widget.hasIndicator) ...[
                            const SizedBox(
                              width: AppPadding.tiny,
                            ),
                            Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              size: widget.iconSize,
                            )
                          ],
                          const SizedBox(
                            width: AppPadding.tiny,
                          )
                        ],
                      ),
                      const SizedBox(
                        height: AppPadding.tiny,
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

class ExpandibleRaw extends StatefulWidget {
  final Widget view;

  final Widget header;

  final double? iconSize;

  final ExpandibleController? controller;

  const ExpandibleRaw(
      {required this.header,
      required this.view,
      this.controller,
      this.iconSize,
      super.key});

  @override
  State<StatefulWidget> createState() => _ExpandRawState();
}

class _ExpandRawState extends State<ExpandibleRaw>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;

  late Animation<double> _heightFactor;

  late final ExpandibleController _listener;

  @override
  void initState() {
    _listener = widget.controller ?? ExpandibleController(true);
    _expandController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
        reverseDuration: const Duration(milliseconds: 200));
    _heightFactor = _expandController.drive(CurveTween(curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_listener.expanded) {
        _expandController.value = _expandController.upperBound;
      }
    });
    _listener.addListener(() {
      if (!mounted) return;
      if (_listener.expanded) {
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
        child: _listener.expanded
            ? Padding(
                padding: const EdgeInsets.all(AppPadding.tiny),
                child: widget.view,
              )
            : null,
        builder: (context, poss) {
          return GestureDetector(
            onTap: () {
              if (_expandController.isAnimating) return;
              _listener.set(!_listener.expanded);
            },
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: AppPadding.tiny,
                      ),
                      widget.header,
                      const SizedBox(
                        width: AppPadding.tiny,
                      ),
                      StyledTooltip(
                        message: _listener.expanded ? 'Show Less' : 'Show More',
                        child: Icon(
                          _listener.expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.black,
                          size: widget.iconSize,
                        ),
                      ),
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

class ExpandibleController extends ChangeNotifier {
  bool expanded = false;

  ExpandibleController(this.expanded);

  set(bool expand) {
    expanded = expand;
    notifyListeners();
  }
}
