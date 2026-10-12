import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/reading_size.dart';

import 'resource_article.dart';

IconData resourceIcon(ResourceTopic topic) => switch (topic) {
  ResourceTopic.blueMealStudy => Icons.menu_book_outlined,
  ResourceTopic.blueMealAtHome => Icons.menu_book_outlined,
  ResourceTopic.bristolScale => Icons.menu_book_outlined,
  ResourceTopic.symptomTracking => Icons.menu_book_outlined,
  ResourceTopic.bluePoop => Icons.public_rounded,
  ResourceTopic.termsOfService => Icons.description_outlined,
};

/// A flat navigation row that can also be embedded outside the resource hub.
class ResourceListTile extends StatelessWidget {
  const ResourceListTile({
    required this.article,
    required this.onTap,
    this.title,
    super.key,
  });

  final ResourceArticle article;
  final VoidCallback onTap;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      minVerticalPadding: 12,
      leading: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Icon(
          resourceIcon(article.topic),
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        title ?? article.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          article.summary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ),
      trailing: Icon(Icons.chevron_right, size: readingIconSize(context)),
      onTap: onTap,
    );
  }
}

/// Width-limited reading column shared by the hub, articles, and sheets.
class ResourceReadingWidth extends StatelessWidget {
  const ResourceReadingWidth({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 400 ? 20 : 28,
        ),
        child: child,
      ),
    ),
  );
}

class ResourceHeading extends StatelessWidget {
  const ResourceHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  );
}
