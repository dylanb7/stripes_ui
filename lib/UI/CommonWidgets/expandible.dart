import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';

class Expandible extends StatefulWidget {
  final Widget header;

  final Widget view;

  final bool canExpand;

  final bool hasIndicator;

  final bool selected;

  final bool highlightOnShrink;

  final Color? highlightColor;

  final double? iconSize;

  final ExpandibleController? listener;

  const Expandible(
      {required this.header,
      required this.view,
      this.canExpand = true,
      this.selected = false,
      this.hasIndicator = true,
      this.highlightOnShrink = false,
      this.iconSize,
      this.highlightColor,
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

  late ExpandibleController _controller;

  @override
  void initState() {
    _expandController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
        reverseDuration: const Duration(milliseconds: 500));
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
        child: _expanded
            ? Padding(
                padding: const EdgeInsets.all(6.0),
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
                _controller.set(_expanded);
              });
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(15.0)),
                  side: (_expanded || widget.highlightOnShrink) &&
                          widget.selected
                      ? BorderSide(
                          color: widget.highlightColor ??
                              Theme.of(context).colorScheme.secondary,
                          width: 5.0)
                      : const BorderSide(width: 0, color: Colors.transparent)),
              elevation: 1.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: 4.0,
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 8.0,
                          ),
                          Expanded(child: widget.header),
                          if (_canExpand && widget.hasIndicator) ...[
                            const SizedBox(
                              width: 4.0,
                            ),
                            Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              size: widget.iconSize,
                            )
                          ],
                          const SizedBox(
                            width: 4.0,
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 4.0,
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
                padding: const EdgeInsets.all(4.0),
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
                        width: 4.0,
                      ),
                      widget.header,
                      const SizedBox(
                        width: 4.0,
                      ),
                      Tooltip(
                        message: _listener.expanded ? 'Show Less' : 'Show More',
                        showDuration: Duration.zero,
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
