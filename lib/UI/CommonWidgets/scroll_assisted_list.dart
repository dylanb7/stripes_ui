import 'package:flutter/material.dart';

typedef ScrollBuilder = Widget Function(
    BuildContext context, ScrollViewProperties properties);

class ScrollAssistedList extends StatefulWidget {
  final ScrollController scrollController;

  final ScrollBuilder builder;

  const ScrollAssistedList(
      {required this.builder, required this.scrollController, super.key});

  @override
  State<StatefulWidget> createState() {
    return _ScrollAssistedListState();
  }
}

class _ScrollAssistedListState extends State<ScrollAssistedList> {
  bool scrollsUp = false, showing = false;

  @override
  void didChangeDependencies() {
    widget.scrollController.addListener(_listen);
    super.didChangeDependencies();
  }

  ScrollPosition get _position =>
      _scrollStateKey.currentState?.position ??
      widget.scrollController.positions.first;

  _listen() {
    try {
      if (!_position.hasContentDimensions) return;
      final bool shouldShow = _position.maxScrollExtent > 0;
      if (shouldShow != showing && mounted) {
        setState(() {
          showing = shouldShow;
        });
      }
      final bool halfWay = widget.scrollController.offset >
          (_position.maxScrollExtent - _position.minScrollExtent) / 2;
      if (halfWay != scrollsUp && mounted) {
        setState(() {
          scrollsUp = halfWay;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  final GlobalKey<ScrollableState> _scrollStateKey =
      GlobalKey<ScrollableState>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.builder(
          context,
          ScrollViewProperties._generateProperties(
              scrollController: widget.scrollController,
              scrollStateKey: _scrollStateKey),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 6.0, bottom: 6.0),
            child: IconButton.filled(
              onPressed: () {
                if (scrollsUp) {
                  widget.scrollController.animateTo(_position.minScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeIn);
                } else {
                  widget.scrollController.animateTo(_position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeIn);
                }
              },
              icon: Icon(scrollsUp ? Icons.arrow_upward : Icons.arrow_downward),
            ),
          ),
        ),
      ],
    );
  }
}

class ScrollViewProperties {
  const ScrollViewProperties._generateProperties(
      {required this.scrollController, required this.scrollStateKey});

  final ScrollController scrollController;

  final GlobalKey<ScrollableState> scrollStateKey;
}
