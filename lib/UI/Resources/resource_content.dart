import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'resource_article.dart';
import 'resource_catalog.dart';
import 'resource_markdown.dart';
import 'resource_widgets.dart';

/// The shared article body. It owns no navigation, scrolling, or app state.
///
/// Supply [sectionId] to embed just one expanded section, for example the
/// Bristol illustrations beside a bowel-movement question.
class ResourceContent extends StatelessWidget {
  const ResourceContent({
    required this.topic,
    this.sectionId,
    this.showIntroduction = true,
    super.key,
  });

  final ResourceTopic topic;
  final String? sectionId;
  final bool showIntroduction;

  @override
  Widget build(BuildContext context) {
    final article = resourceArticle(topic);
    final sections = sectionId == null
        ? article.sections
        : article.sections.where((section) => section.id == sectionId).toList();
    if (sections.isEmpty && sectionId != null) {
      throw ArgumentError.value(
        sectionId,
        'sectionId',
        'Unknown resource section',
      );
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIntroduction) ...[
          Row(
            children: [
              Icon(
                resourceIcon(topic),
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(child: ResourceHeading('STRiPES guide')),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              article.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            article.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 28),
        ],
        for (final section in sections)
          ResourceSectionView(
            key: ValueKey('${topic.slug}/${section.id}/${sectionId != null}'),
            section: section,
            expanded: sectionId != null,
            omitMarkdownTitle: showIntroduction,
          ),
      ],
    );
  }
}

/// An individual section, reusable in another form or screen.
class ResourceSectionView extends StatelessWidget {
  const ResourceSectionView({
    required this.section,
    this.expanded = false,
    this.omitMarkdownTitle = false,
    super.key,
  });

  final ResourceSection section;
  final bool expanded;
  final bool omitMarkdownTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: DefaultTextStyle.merge(
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final paragraph in section.paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(paragraph),
              ),
            for (final bullet in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•'),
                    const SizedBox(width: 12),
                    Expanded(child: Text(bullet)),
                  ],
                ),
              ),
            for (var i = 0; i < section.steps.length; i++)
              _StepRow(number: i + 1, step: section.steps[i]),
            if (section.showBristolScale) const BristolScaleGuide(),
            if (section.markdown != null)
              ResourceMarkdown(
                // The article introduction already supplies the document title.
                data: omitMarkdownTitle
                    ? section.markdown!.replaceFirst(RegExp(r'^# [^\n]+\n'), '')
                    : section.markdown!,
              ),
            for (final link in section.links)
              Align(
                alignment: Alignment.centerLeft,
                child: ResourceLinkButton(link: link),
              ),
          ],
        ),
      ),
    );
    // Long documents read as a continuous page instead of an extra accordion.
    if (section.markdown != null) return content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!expanded)
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
        if (expanded) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Semantics(
              header: true,
              child: Text(
                section.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          content,
        ] else
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(vertical: 8),
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            initiallyExpanded: section.initiallyExpanded,
            maintainState: true,
            title: Text(
              section.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [content],
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.step});

  final int number;
  final ResourceStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            ),
            child: Text(
              '$number',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(step.description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The same seven illustrations used in the Bristol recording question.
class BristolScaleGuide extends StatelessWidget {
  const BristolScaleGuide({super.key});

  static const _types = [
    ('Separate hard lumps', 'Separate hard lumps, like nuts (hard to pass).'),
    ('Lumpy sausage', 'Sausage-shaped but lumpy.'),
    ('Cracks on the surface', 'Like a sausage but with cracks on its surface.'),
    ('Smooth and soft', 'Like a sausage or snake, smooth and soft.'),
    ('Soft blobs', 'Soft blobs with clear-cut edges (passed easily).'),
    ('Mushy pieces', 'Fluffy pieces with ragged edges, a mushy stool.'),
    ('Entirely liquid', 'Liquid consistency with no solid pieces.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < _types.length; i++) ...[
          if (i != 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Image.asset(
                    'packages/stripes_ui/assets/images/poop${i + 1}.png',
                    width: 76,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type ${i + 1}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _types[i].$1,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _types[i].$2,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class ResourceLinkButton extends StatelessWidget {
  const ResourceLinkButton({required this.link, super.key});

  final ResourceLink link;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    ),
    onPressed: () => _open(context),
    icon: Icon(
      link.url.startsWith('mailto:') ? Icons.mail_outline : Icons.open_in_new,
      size: 18,
    ),
    label: Text(link.label),
  );

  Future<void> _open(BuildContext context) async {
    bool opened;
    try {
      opened = await launchUrl(
        Uri.parse(link.url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open ${link.url}. Please try again.'),
        ),
      );
    }
  }
}
