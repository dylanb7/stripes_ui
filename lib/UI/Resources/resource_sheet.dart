import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/reading_size.dart';

import 'resource_article.dart';
import 'resource_catalog.dart';
import 'resource_content.dart';
import 'resource_widgets.dart';

/// Opens a guide, or one focused section, without changing the current route.
///
/// Uses the root navigator so help sits above forms and floating navigation.
/// This API needs only a Material app; no Riverpod or study state is required.
Future<void> showResourceSheet(
  BuildContext context, {
  required ResourceTopic topic,
  String? sectionId,
}) {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= 840 || size.height < 480) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(maxWidth: 720),
        child: SizedBox(
          height: size.height * 0.85,
          child: ResourceSheetBody(topic: topic, sectionId: sectionId),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, controller) => ResourceSheetBody(
        topic: topic,
        sectionId: sectionId,
        scrollController: controller,
      ),
    ),
  );
}

/// Drop-in contextual help, for example:
///
/// ```dart
/// const ResourceInfoButton(
///   topic: ResourceTopic.bristolScale,
///   sectionId: 'stool-types',
/// )
/// ```
class ResourceInfoButton extends StatelessWidget {
  const ResourceInfoButton({
    required this.topic,
    this.sectionId,
    this.tooltip,
    super.key,
  });

  final ResourceTopic topic;
  final String? sectionId;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip ?? resourceArticle(topic).title,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    icon: Icon(Icons.info_outline_rounded, size: readingIconSize(context)),
    color: Theme.of(context).colorScheme.primary,
    onPressed: () =>
        showResourceSheet(context, topic: topic, sectionId: sectionId),
  );
}

/// Scrollable resource content for an adaptive sheet or dialog.
class ResourceSheetBody extends StatefulWidget {
  const ResourceSheetBody({
    required this.topic,
    this.sectionId,
    this.scrollController,
    super.key,
  });

  final ResourceTopic topic;
  final String? sectionId;
  final ScrollController? scrollController;

  @override
  State<ResourceSheetBody> createState() => _ResourceSheetBodyState();
}

class _ResourceSheetBodyState extends State<ResourceSheetBody> {
  late final ScrollController _controller =
      widget.scrollController ?? ScrollController();
  bool _showFullGuide = false;
  double _focusedOffset = 0;

  bool get _isFocused => widget.sectionId != null && !_showFullGuide;

  @override
  void dispose() {
    if (widget.scrollController == null) _controller.dispose();
    super.dispose();
  }

  void _setFullGuide(bool show) {
    if (show && _controller.hasClients) {
      _focusedOffset = _controller.offset;
    }
    setState(() => _showFullGuide = show);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.jumpTo(
        show
            ? 0
            : _focusedOffset.clamp(0, _controller.position.maxScrollExtent),
      );
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 12,
            bottom: 4,
            top: 4,
          ),
          child: Row(
            children: [
              if (_showFullGuide)
                IconButton(
                  tooltip: 'Back to quick help',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => _setFullGuide(false),
                  icon: const Icon(Icons.arrow_back),
                ),
              Expanded(
                child: Text(
                  _isFocused
                      ? 'Quick help'
                      : _showFullGuide
                      ? 'Full guide'
                      : 'Help and resources',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: 'Close resources',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            controller: _controller,
            child: ResourceReadingWidth(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ResourceContent(
                      topic: widget.topic,
                      sectionId: _isFocused ? widget.sectionId : null,
                      showIntroduction: !_isFocused,
                    ),
                    if (_isFocused)
                      TextButton.icon(
                        onPressed: () => _setFullGuide(true),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: const Text('Read full guide'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.sectionId != null) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
