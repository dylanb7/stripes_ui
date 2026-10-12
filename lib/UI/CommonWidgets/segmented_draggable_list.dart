import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

class SegmentedDraggablePage<T> extends Equatable {
  final String? id;

  final String? header;

  final List<T> items;

  const SegmentedDraggablePage({this.id, required this.items, this.header});

  void insert(int index, T item) {
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

class SegmentedPageActions {
  final VoidCallback? moveUp;
  final VoidCallback? moveDown;
  final VoidCallback? remove;
  final ValueChanged<String>? updateHeader;

  const SegmentedPageActions({
    this.moveUp,
    this.moveDown,
    this.remove,
    this.updateHeader,
  });
}

class SegmentedDraggableList<T extends Object> extends StatefulWidget {
  final Function setNotEditing;

  final Future<bool> Function(List<SegmentedDraggablePage<T>> newLayouts) save;

  final List<SegmentedDraggablePage<T>> layouts;

  final Widget? Function(
    BuildContext context,
    SegmentedDraggablePage<T> page,
    int index,
    SegmentedPageActions actions,
  )?
  pageHeaderBuilder;

  final Widget Function(BuildContext context, Widget child, int index)?
  pageDecorator;

  final Widget? Function(BuildContext context, T item)? feedback;

  final Widget Function(BuildContext context, T? value, bool isNewPage)?
  buildDropPreview;

  final Widget? Function(BuildContext context, T item)? childOnDrag;

  final Widget? Function(BuildContext context, T item)? childWhenDragging;

  final Widget Function(
    BuildContext context,
    T item,
    Widget? dragHandle,
    bool enabled,
  )
  buildItem;

  final bool Function(
    List<SegmentedDraggablePage<T>> layouts,
    DragTargetDetails<T> details,
  )?
  shouldAccept;

  final bool Function(SegmentedDraggablePage<T> page, T item)? hasTargets;

  final bool Function(SegmentedDraggablePage<T> page, T item)? draggable;

  final Alignment handleAlignment;

  final bool canAddFirstPage, canAddLastPage;
  final bool canCreatePageByDragging;

  final Widget? header;

  const SegmentedDraggableList({
    required this.layouts,
    required this.setNotEditing,
    required this.save,
    required this.buildItem,
    this.shouldAccept,
    this.pageHeaderBuilder,
    this.pageDecorator,
    this.canAddFirstPage = true,
    this.canAddLastPage = true,
    this.canCreatePageByDragging = true,
    this.feedback,
    this.childOnDrag,
    this.childWhenDragging,
    this.buildDropPreview,
    this.hasTargets,
    this.draggable,
    this.header,
    this.handleAlignment = Alignment.centerRight,
    super.key,
  });

  factory SegmentedDraggableList.singlePage({
    required SegmentedDraggablePage<T> page,
    required Function setNotEditing,
    required Future<bool> Function(List<SegmentedDraggablePage<T>> newLayouts)
    save,
    required Widget Function(
      BuildContext context,
      T item,
      Widget? dragHandle,
      bool enabled,
    )
    buildItem,
  }) => SegmentedDraggableList(
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
  int nextDraftPageId = 0;

  String _draftPageId() =>
      'draft-page-${DateTime.now().microsecondsSinceEpoch}-${nextDraftPageId++}';

  @override
  void initState() {
    scrollController = ScrollController();
    // Editing must not mutate the provider-owned page/question lists before the
    // user explicitly saves their changes.
    layouts = widget.layouts
        .map(
          (page) => page.copyWith(
            id: page.id ?? _draftPageId(),
            items: List<T>.from(page.items),
          ),
        )
        .toList();
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
          left: AppPadding.large,
          right: AppPadding.large,
          bottom: AppPadding.large,
          child: Card(
            elevation: 4,
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.small),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => widget.setNotEditing(),
                          child: Text(context.translate.stampDeleteCancel),
                        ),
                      ),
                      const SizedBox(width: AppPadding.small),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (await widget.save(layouts)) {
                              widget.setNotEditing();
                            } else if (context.mounted) {
                              showSnack(context, "Failed to edit layouts");
                            }
                          },
                          child: Text(context.translate.saveChanges),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _moveUp() {
    final double height = (listHeight ?? 400);
    final double endpoint = max(
      scrollController.offset - height,
      scrollController.position.minScrollExtent,
    );
    final int travelInMillis =
        (((endpoint - scrollController.offset).abs() / height) *
                Durations.long1.inMilliseconds)
            .round();
    if (travelInMillis == 0) return;
    scrollController.animateTo(
      endpoint,
      curve: Curves.linear,
      duration: Duration(milliseconds: travelInMillis),
    );
  }

  void _moveDown() {
    final double height = (listHeight ?? 400);
    final double endpoint = min(
      scrollController.offset + height,
      scrollController.position.maxScrollExtent,
    );
    final int travelInMillis =
        (((endpoint - scrollController.offset).abs() / height) *
                Durations.long1.inMilliseconds)
            .round();
    if (travelInMillis == 0) return;
    scrollController.animateTo(
      endpoint,
      curve: Curves.linear,
      duration: Duration(milliseconds: travelInMillis),
    );
  }

  Widget _buildDropPreview(BuildContext context, T? value, bool isNewPage) {
    if (widget.buildDropPreview != null) {
      return widget.buildDropPreview!(context, value, isNewPage);
    }
    return SizedBox(
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildList() {
    List<Widget> widgets = [];

    for (int i = 0; i < layouts.length; i++) {
      final SegmentedDraggablePage<T> page = layouts[i];
      List<Widget> pageWidgets = [];

      void movePage(int offset) {
        final currentIndex = layouts.indexOf(page);
        final targetIndex = currentIndex + offset;
        if (currentIndex < 0 ||
            targetIndex < 0 ||
            targetIndex >= layouts.length) {
          return;
        }
        setState(() {
          layouts.removeAt(currentIndex);
          layouts.insert(targetIndex, page);
        });
      }

      Widget? header = widget.pageHeaderBuilder?.call(
        context,
        page,
        i,
        SegmentedPageActions(
          moveUp: i > 0 ? () => movePage(-1) : null,
          moveDown: i < layouts.length - 1 ? () => movePage(1) : null,
          remove: page.items.isEmpty
              ? () => setState(() => layouts.remove(page))
              : null,
          updateHeader: (header) {
            final pageIndex = layouts.indexOf(page);
            if (pageIndex < 0) return;
            setState(() {
              layouts[pageIndex] = page.copyWith(header: header);
            });
          },
        ),
      );
      if (header != null) pageWidgets.add(header);

      const double sepHeight = AppPadding.xl;

      const Widget sep = Divider(
        height: sepHeight,
        endIndent: AppPadding.large,
        indent: AppPadding.large,
      );

      void onAccept(DragTargetDetails<T> details, int insertIndex) {
        final targetPageIndex = layouts.indexOf(page);
        if (targetPageIndex < 0) return;

        int sourcePageIndex = -1;
        int sourceItemIndex = -1;
        for (int i = 0; i < layouts.length; i++) {
          final itemIndex = layouts[i].items.indexOf(details.data);
          if (itemIndex >= 0) {
            sourcePageIndex = i;
            sourceItemIndex = itemIndex;
            break;
          }
        }
        if (sourcePageIndex < 0) return;

        setState(() {
          if (sourcePageIndex == targetPageIndex) {
            final items = List<T>.from(layouts[targetPageIndex].items);
            final item = items.removeAt(sourceItemIndex);
            final adjustedIndex = insertIndex > sourceItemIndex
                ? insertIndex - 1
                : insertIndex;
            items.insert(adjustedIndex.clamp(0, items.length), item);
            layouts[targetPageIndex] = layouts[targetPageIndex].copyWith(
              items: items,
            );
            return;
          }

          final sourceItems = List<T>.from(layouts[sourcePageIndex].items)
            ..removeAt(sourceItemIndex);
          layouts[sourcePageIndex] = layouts[sourcePageIndex].copyWith(
            items: sourceItems,
          );

          final refreshedTargetIndex = layouts.indexWhere(
            (candidate) => candidate.id == page.id,
          );
          if (refreshedTargetIndex < 0) return;
          final targetItems = List<T>.from(layouts[refreshedTargetIndex].items);
          targetItems.insert(
            insertIndex.clamp(0, targetItems.length),
            details.data,
          );
          layouts[refreshedTargetIndex] = layouts[refreshedTargetIndex]
              .copyWith(items: targetItems);
        });
      }

      if (page.items.isEmpty) {
        pageWidgets.add(
          DragTarget<T>(
            onWillAcceptWithDetails: (details) =>
                widget.shouldAccept?.call(layouts, details) ?? true,
            onAcceptWithDetails: (details) {
              onAccept(details, 0);
            },
            builder: (context, candidates, rejects) => Container(
              margin: const EdgeInsets.all(AppPadding.medium),
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.medium,
                vertical: AppPadding.xl,
              ),
              decoration: BoxDecoration(
                color: candidates.isEmpty
                    ? Theme.of(context).colorScheme.surfaceContainerLowest
                    : Theme.of(context).colorScheme.primaryContainer,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(AppRounding.small),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.move_down_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppPadding.tiny),
                  Text(
                    context.translate.emptySectionDropHere,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      for (int j = 0; j < page.items.length; j++) {
        final T currentItem = page.items[j];

        bool isNeighbor(T candidate) {
          if (candidate == currentItem) return true;
          // This target inserts before currentItem. Moving the immediately
          // preceding item here would be a no-op.
          return j > 0 && page.items[j - 1] == candidate;
        }

        Widget separator = j == 0 ? const SizedBox(height: sepHeight) : sep;
        bool hasTargets = widget.hasTargets?.call(page, currentItem) ?? true;
        pageWidgets.add(
          hasTargets
              ? DragTarget<T>(
                  builder: (context, List<T?> candidates, rejects) {
                    if (candidates.isEmpty || candidates[0] == null) return sep;
                    final T candidate = candidates[0]!;
                    return !isNeighbor(candidate)
                        ? _buildDropPreview(context, candidates[0], false)
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
        pageWidgets.add(
          enabled
              ? _buildDraggableItem(currentItem)
              : widget.buildItem(context, currentItem, null, enabled),
        );
      }
      if (page.items.isNotEmpty) {
        bool hasTargets =
            widget.hasTargets?.call(page, page.items.last) ?? true;
        pageWidgets.add(
          hasTargets
              ? DragTarget<T>(
                  onWillAcceptWithDetails: (details) {
                    final bool isAlreadyLast =
                        details.data == page.items[page.items.length - 1];
                    if (isAlreadyLast) return false;
                    return widget.shouldAccept?.call(layouts, details) ?? true;
                  },
                  onAcceptWithDetails: (details) {
                    onAccept(details, page.items.length);
                  },
                  builder: (context, List<T?> candidates, rejects) {
                    if (candidates.isEmpty || candidates[0] == null) return sep;
                    final T candidate = candidates[0]!;
                    return page.items.isEmpty || candidate != page.items.last
                        ? _buildDropPreview(context, candidates[0], false)
                        : const SizedBox(height: sepHeight);
                  },
                )
              : const SizedBox(height: sepHeight),
        );
      }

      Widget pageContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: pageWidgets,
      );

      if (widget.pageDecorator != null) {
        pageContent = widget.pageDecorator!(context, pageContent, i);
      }
      widgets.add(pageContent);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        listHeight = constraints.maxHeight;
        return ListView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          children: [
            if (widget.header != null) widget.header!,
            const SizedBox(height: AppPadding.medium),
            if (widget.canAddFirstPage && widget.canCreatePageByDragging)
              DragTarget<T>(
                builder: (context, List<T?> candidates, List<dynamic> rejects) {
                  if (candidates.isEmpty || candidates[0] == null) {
                    return const SizedBox(height: AppPadding.xl);
                  }
                  final T candidate = candidates[0]!;
                  return _buildDropPreview(context, candidate, true);
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
                    0,
                    SegmentedDraggablePage(
                      id: _draftPageId(),
                      items: [details.data],
                    ),
                  );
                  setState(() {});
                },
              ),
            ...widgets,
            if (!isDragging && widget.canAddLastPage)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.large,
                ),
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      layouts.add(
                        SegmentedDraggablePage(
                          id: _draftPageId(),
                          items: const [],
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text(context.translate.addSection),
                ),
              ),
            if (isDragging &&
                widget.canAddLastPage &&
                widget.canCreatePageByDragging) ...[
              Padding(
                padding: const EdgeInsets.only(
                  left: AppPadding.large,
                  bottom: AppPadding.tiny,
                ),
                child: Text(
                  context.translate.sectionNumber(layouts.length + 1),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
              DragTarget<T>(
                builder: (context, List<T?> candidates, List<dynamic> rejects) {
                  if (candidates.isEmpty || candidates[0] == null) {
                    return const SizedBox(height: AppPadding.xl);
                  }
                  final T candidate = candidates[0]!;
                  return _buildDropPreview(context, candidate, true);
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
                    SegmentedDraggablePage(
                      id: _draftPageId(),
                      items: [details.data],
                    ),
                  );
                  setState(() {});
                },
              ),
            ],
            const SizedBox(height: 150),
          ],
        );
      },
    );
  }

  Widget _buildDraggableItem(T item) {
    Widget feedback({required Widget child}) {
      final Widget? customFeedback = widget.feedback?.call(context, item);
      if (customFeedback != null) return customFeedback;
      return Material(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - (AppPadding.xl * 2),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor,
                  blurStyle: BlurStyle.outer,
                  blurRadius: 2.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }

    Widget handle = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRounding.small),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.small),
        child: Icon(
          Icons.drag_indicator,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    final Widget dragHandle = Draggable<T>(
      affinity: Axis.vertical,
      maxSimultaneousDrags: 1,
      data: item,
      hitTestBehavior: HitTestBehavior.deferToChild,
      feedback: FractionalTranslation(
        translation: Offset(
          -(widget.handleAlignment.x + 1) / 2,
          -(widget.handleAlignment.y + 1) / 2,
        ),
        child: feedback(child: widget.buildItem(context, item, handle, true)),
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
