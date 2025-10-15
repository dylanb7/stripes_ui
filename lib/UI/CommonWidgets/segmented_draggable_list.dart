import 'dart:math';
import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/paddings.dart';

class SegmentedDraggablePage<T> extends Equatable {
  final String? id;

  final String? header;

  final List<T> items;

  const SegmentedDraggablePage({
    this.id,
    required this.items,
    this.header,
  });

  insert(int index, T item) {
    items.insert(index, item);
  }

  SegmentedDraggablePage<T> copyWith({
    String? id,
    String? header,
    List<T>? items,
  }) {
    return SegmentedDraggablePage(
      id: id ?? this.id,
      header: header ?? this.header,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [id, header, items];
}

class SegmentedDraggableList<T extends Object> extends StatefulWidget {
  final Function setNotEditing;

  final Future<bool> Function(List<SegmentedDraggablePage<T>> newLayouts) save;

  final List<SegmentedDraggablePage<T>> layouts;

  final Widget? Function(
          BuildContext context, SegmentedDraggablePage<T> page, int index)?
      pageHeaderBuilder;

  final Widget? Function(BuildContext context, T item)? feedback;

  final Widget Function(BuildContext context, T? value)? buildDropPreview;

  final Widget? Function(BuildContext context, T item)? childOnDrag;

  final Widget? Function(BuildContext context, T item)? childWhenDragging;

  final Widget Function(
      BuildContext context, T item, Widget? dragHandle, bool enabled) buildItem;

  final bool Function(List<SegmentedDraggablePage<T>> layouts,
      DragTargetDetails<T> details)? shouldAccept;

  final bool Function(SegmentedDraggablePage<T> page, T item)? hasTargets;

  final bool Function(SegmentedDraggablePage<T> page, T item)? draggable;

  final bool canAddFirstPage, canAddLastPage;

  const SegmentedDraggableList({
    required this.layouts,
    required this.setNotEditing,
    required this.save,
    required this.buildItem,
    this.shouldAccept,
    this.pageHeaderBuilder,
    this.canAddFirstPage = true,
    this.canAddLastPage = true,
    this.feedback,
    this.childOnDrag,
    this.childWhenDragging,
    this.buildDropPreview,
    this.hasTargets,
    this.draggable,
    super.key,
  });

  factory SegmentedDraggableList.singlePage(
          {required SegmentedDraggablePage<T> page,
          required Function setNotEditing,
          required Future<bool> Function(
                  List<SegmentedDraggablePage<T>> newLayouts)
              save,
          required Widget Function(BuildContext context, T item,
                  Widget? dragHandle, bool enabled)
              buildItem}) =>
      SegmentedDraggableList(
        layouts: [page],
        setNotEditing: setNotEditing,
        save: save,
        buildItem: buildItem,
        canAddFirstPage: false,
        canAddLastPage: false,
      );

  @override
  State<SegmentedDraggableList> createState() {
    return _SegmentedDraggableListState<T>();
  }
}

class _SegmentedDraggableListState<T extends Object>
    extends State<SegmentedDraggableList<T>>
    with SingleTickerProviderStateMixin {
  late List<SegmentedDraggablePage<T>> layouts;

  late final ScrollController scrollController;

  bool isDragging = false;

  double? listHeight;

  @override
  void initState() {
    scrollController = ScrollController();
    layouts = widget.layouts;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildList(),
        !isDragging
            ? const SizedBox()
            : Align(
                alignment: Alignment.topCenter,
                child: DragTarget<T>(
                  builder: (context, List<T?> candidateData, rejectedData) =>
                      Container(
                    height: 40.0,
                    width: double.infinity,
                    color: Colors.transparent,
                  ),
                  onWillAcceptWithDetails: (_) {
                    _moveUp();
                    return false;
                  },
                ),
              ),
        !isDragging
            ? const SizedBox()
            : Align(
                alignment: Alignment.bottomCenter,
                child: DragTarget<T>(
                  builder: (context, List<T?> candidateData, rejectedData) =>
                      Container(
                    height: 20.0,
                    width: double.infinity,
                    color: Colors.transparent,
                  ),
                  onWillAcceptWithDetails: (_) {
                    _moveDown();
                    return false;
                  },
                ),
              ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppPadding.xxl,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface,
                    spreadRadius: 2,
                    blurRadius: 2,
                    blurStyle: BlurStyle.outer,
                    offset: const Offset(0, 0),
                  ),
                ],
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(100.0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    child: TextButton(
                      onPressed: () {
                        widget.setNotEditing();
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                  Container(
                    width: 1.0,
                    height:
                        Theme.of(context).buttonTheme.height - AppPadding.small,
                    color: Theme.of(context).dividerColor,
                  ),
                  SizedBox(
                    width: 100,
                    child: TextButton(
                      onPressed: () async {
                        if (await widget.save(layouts)) {
                          widget.setNotEditing();
                        } else if (context.mounted) {
                          showSnack(context, "Failed to edit layouts");
                        }
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  _moveUp() {
    final double height = (listHeight ?? 400);
    final double endpoint = max(scrollController.offset - height,
        scrollController.position.minScrollExtent);
    final int travelInMillis =
        (((endpoint - scrollController.offset).abs() / height) *
                Durations.long1.inMilliseconds)
            .round();
    if (travelInMillis == 0) return;
    scrollController.animateTo(endpoint,
        curve: Curves.linear, duration: Duration(milliseconds: travelInMillis));
  }

  _moveDown() {
    final double height = (listHeight ?? 400);
    final double endpoint = min(scrollController.offset + height,
        scrollController.position.maxScrollExtent);
    final int travelInMillis =
        (((endpoint - scrollController.offset).abs() / height) *
                Durations.long1.inMilliseconds)
            .round();
    if (travelInMillis == 0) return;
    scrollController.animateTo(endpoint,
        curve: Curves.linear, duration: Duration(milliseconds: travelInMillis));
  }

  Widget _buildDropPreview(BuildContext context, T? value) {
    if (widget.buildDropPreview != null) {
      return widget.buildDropPreview!(context, value);
    }
    return SizedBox(
        height: 60,
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
        ));
  }

  Widget _buildList() {
    List<Widget> widgets = [];

    for (int i = 0; i < layouts.length; i++) {
      final SegmentedDraggablePage<T> page = layouts[i];

      Widget? header = widget.pageHeaderBuilder?.call(context, page, i);
      if (header != null) widgets.add(header);

      const double sepHeight = AppPadding.xl;

      const Widget sep = Divider(
        height: sepHeight,
        endIndent: AppPadding.large,
        indent: AppPadding.large,
      );

      void onAccept(DragTargetDetails<T> details, int insertIndex) {
        bool found = false;
        bool wasInSameLayout = false;
        for (int i = 0; i < layouts.length; i++) {
          final SegmentedDraggablePage<T> pageLayout = layouts[i];
          for (int j = 0; j < pageLayout.items.length; j++) {
            if (pageLayout.items[j] == details.data) {
              if (page == pageLayout && insertIndex > j) {
                wasInSameLayout = true;
              }
              final SegmentedDraggablePage<T> newLayout =
                  pageLayout.copyWith(items: pageLayout.items..removeAt(j));
              if (newLayout.items.isEmpty) {
                layouts.removeAt(i);
              } else {
                layouts[i] = newLayout;
              }
              found = true;
              break;
            }
          }
          if (found) break;
        }

        page.insert(
            wasInSameLayout ? insertIndex - 1 : insertIndex, details.data);
        setState(() {});
      }

      for (int j = 0; j < page.items.length; j++) {
        final T currentItem = page.items[j];

        bool isNeighbor(T candidate) {
          if (candidate == currentItem) return true;
          if ((j + 1 < page.items.length && page.items[j + 1] == currentItem) ||
              (j - 1 >= 0 && page.items[j - 1] == currentItem)) {
            return true;
          }
          return false;
        }

        Widget separator = j == 0
            ? const SizedBox(
                height: sepHeight,
              )
            : sep;
        bool hasTargets = widget.hasTargets?.call(page, currentItem) ?? true;
        widgets.add(
          hasTargets
              ? DragTarget<T>(
                  builder: (context, List<T?> candidates, rejects) {
                    if (candidates.isEmpty || candidates[0] == null) return sep;
                    final T candidate = candidates[0]!;
                    return !isNeighbor(candidate)
                        ? _buildDropPreview(context, candidates[0])
                        : separator;
                  },
                  onWillAcceptWithDetails: (details) {
                    final bool neighbor = isNeighbor(details.data);
                    if (neighbor) return false;
                    return widget.shouldAccept?.call(layouts, details) ?? true;
                  },
                  onAcceptWithDetails: (details) {
                    onAccept(details, j);
                  },
                )
              : separator,
        );
        final bool enabled = widget.draggable?.call(page, currentItem) ?? true;
        widgets.add(enabled
            ? _buildDraggableItem(currentItem)
            : widget.buildItem(context, currentItem, null, enabled));
      }
      bool hasTargets = widget.hasTargets?.call(page, page.items.last) ?? true;
      widgets.add(
        hasTargets
            ? DragTarget<T>(
                onWillAcceptWithDetails: (details) {
                  final bool isNeighbor =
                      details.data == page.items[page.items.length - 1];
                  if (!isNeighbor) return false;
                  return widget.shouldAccept?.call(layouts, details) ?? true;
                },
                onAcceptWithDetails: (details) {
                  onAccept(details, page.items.length);
                },
                builder: (context, List<T?> candidates, rejects) {
                  if (candidates.isEmpty || candidates[0] == null) return sep;
                  final T candidate = candidates[0]!;
                  return page.items.isEmpty || candidate != page.items.last
                      ? _buildDropPreview(context, candidates[0])
                      : const SizedBox(
                          height: sepHeight,
                        );
                },
              )
            : const SizedBox(
                height: sepHeight,
              ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      listHeight = constraints.maxHeight;
      return ListView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        children: [
          const SizedBox(
            height: AppPadding.xxxl,
          ),
          if (widget.canAddFirstPage)
            DragTarget<T>(
              builder: (context, List<T?> candidates, List<dynamic> rejects) {
                if (candidates.isEmpty || candidates[0] == null) {
                  return const SizedBox(
                    height: AppPadding.xl,
                  );
                }
                final T candidate = candidates[0]!;
                return _buildDropPreview(context, candidate);
              },
              onWillAcceptWithDetails: (details) {
                return widget.shouldAccept?.call(layouts, details) ?? true;
              },
              onAcceptWithDetails: (details) {
                bool found = false;
                for (int i = 0; i < layouts.length; i++) {
                  final SegmentedDraggablePage<T> pageLayout = layouts[i];
                  for (int j = 0; j < pageLayout.items.length; j++) {
                    if (pageLayout.items[j] == details.data) {
                      final SegmentedDraggablePage<T> newPage = pageLayout
                          .copyWith(items: pageLayout.items..removeAt(j));

                      if (newPage.items.isEmpty) {
                        layouts.removeAt(i);
                      } else {
                        layouts[i] = newPage;
                      }
                      found = true;
                      break;
                    }
                  }
                  if (found) break;
                }
                layouts.insert(
                    0, SegmentedDraggablePage(items: [details.data]));
                setState(() {});
              },
            ),
          ...widgets,
          if (isDragging && widget.canAddLastPage) ...[
            Padding(
              padding: const EdgeInsets.only(
                  left: AppPadding.large, bottom: AppPadding.tiny),
              child: Text(
                "Page ${layouts.length + 1}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
            DragTarget<T>(
              builder: (context, List<T?> candidates, List<dynamic> rejects) {
                if (candidates.isEmpty || candidates[0] == null) {
                  return const SizedBox(
                    height: AppPadding.xl,
                  );
                }
                final T candidate = candidates[0]!;
                return _buildDropPreview(context, candidate);
              },
              onWillAcceptWithDetails: (details) {
                return widget.shouldAccept?.call(layouts, details) ?? true;
              },
              onAcceptWithDetails: (details) {
                bool found = false;
                for (int i = 0; i < layouts.length; i++) {
                  final SegmentedDraggablePage<T> pageLayout = layouts[i];
                  for (int j = 0; j < pageLayout.items.length; j++) {
                    if (pageLayout.items[j] == details.data) {
                      final SegmentedDraggablePage<T> newLayout = pageLayout
                          .copyWith(items: pageLayout.items..removeAt(j));

                      if (newLayout.items.isEmpty) {
                        layouts.removeAt(i);
                      } else {
                        layouts[i] = newLayout;
                      }
                      found = true;
                      break;
                    }
                  }
                  if (found) break;
                }
                layouts.add(
                  SegmentedDraggablePage(items: [details.data]),
                );
                setState(() {});
              },
            ),
          ],
          const SizedBox(
            height: 150,
          ),
        ],
      );
    });
  }

  Widget _buildDraggableItem(T item) {
    Widget feedback({required Widget child}) {
      final Widget? customFeedback = widget.feedback?.call(context, item);
      if (customFeedback != null) return customFeedback;
      return Material(
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).primaryColor,
                      blurStyle: BlurStyle.outer,
                      blurRadius: 2.0,
                      spreadRadius: 2.0)
                ],
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    Widget handle = DecoratedBox(
      decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppRounding.small))),
      child: const Icon(Icons.drag_handle),
    );

    final Widget dragHandle = Draggable<T>(
      affinity: Axis.vertical,
      maxSimultaneousDrags: 1,
      data: item,
      hitTestBehavior: HitTestBehavior.deferToChild,
      feedback: feedback(
        child: widget.buildItem(context, item, handle, true),
      ),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () {
        setState(() {
          isDragging = true;
        });
      },
      onDragEnd: (_) {
        setState(() {
          isDragging = false;
        });
      },
      /*childWhenDragging: widget.childWhenDragging?.call(context, item) ??
          widget.buildItem(context, item, null, true),*/
      child: handle,
    );

    return widget.buildItem(context, item, dragHandle, true);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
