import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/paddings.dart';

typedef ScrollBuilder = Widget Function(
    BuildContext context, ScrollViewProperties properties);

class ScrollAssistedList extends StatefulWidget {
  final ScrollController scrollController;

  final ScrollBuilder builder;

  final EdgeInsets? padding;

  const ScrollAssistedList(
      {required this.builder,
      required this.scrollController,
      this.padding,
      super.key});

  @override
  State<StatefulWidget> createState() {
    return _ScrollAssistedListState();
  }
}

class _ScrollAssistedListState extends State<ScrollAssistedList> {
  bool scrollsUp = false, showing = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_listen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          showing = _position?.hasContentDimensions == true
              ? (_position?.maxScrollExtent ?? 0) > 0
              : false;
        });
      }
    });
  }

  ScrollPosition? get _position =>
      _scrollStateKey.currentState?.position ??
      (widget.scrollController.hasClients
          ? widget.scrollController.position
          : null);

  _listen() {
    try {
      if (_position == null || !_position!.hasContentDimensions) return;
      final bool halfWay = widget.scrollController.offset >
          (_position!.maxScrollExtent - _position!.minScrollExtent) / 2;
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
        if (showing)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: widget.padding ??
                  const EdgeInsets.only(
                      right: AppPadding.tiny, bottom: AppPadding.tiny),
              child: IconButton.filled(
                onPressed: () {
                  if (scrollsUp) {
                    widget.scrollController.animateTo(
                        _position?.minScrollExtent ?? 0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeIn);
                  } else {
                    widget.scrollController.animateTo(
                        _position?.maxScrollExtent ?? 0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeIn);
                  }
                },
                icon:
                    Icon(scrollsUp ? Icons.arrow_upward : Icons.arrow_downward),
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
