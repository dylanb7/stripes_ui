import 'package:flutter/material.dart';

import 'resource_article.dart';
import 'resource_catalog.dart';
import 'resource_content.dart';
import 'resource_widgets.dart';

/// A standalone resource hub, also used by the app's Account route.
class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({this.onOpenResource, this.onBack, super.key});

  final ValueChanged<ResourceTopic>? onOpenResource;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ResourcePage(
      onBack: onBack,
      child: ResourceReadingWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Find help with tracking and the Blue Meal Study.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
            const SizedBox(height: 24),
            const ResourceHeading('STRiPES GUIDES'),
            const SizedBox(height: 12),
            for (final (topic, title) in const [
              (ResourceTopic.bristolScale, 'Choose a stool type'),
              (ResourceTopic.symptomTracking, 'Log symptoms'),
              (ResourceTopic.blueMealStudy, 'Understand the Blue Meal Study'),
              (ResourceTopic.blueMealAtHome, 'At-home guide and muffin recipe'),
            ]) ...[
              const Divider(height: 1),
              ResourceListTile(
                article: resourceArticle(topic),
                title: title,
                onTap: () => _open(context, topic),
              ),
            ],
            const Divider(height: 1),
            const SizedBox(height: 36),
            const ResourceHeading('MORE INFORMATION'),
            const SizedBox(height: 12),
            for (final topic in [
              ResourceTopic.bluePoop,
              ResourceTopic.termsOfService,
            ]) ...[
              const Divider(height: 1),
              ResourceListTile(
                article: resourceArticle(topic),
                onTap: () => _open(context, topic),
              ),
            ],
            const Divider(height: 1),
            const SizedBox(height: 24),
            const ResourceLinkButton(
              link: ResourceLink(
                label: 'Contact support',
                url: 'mailto:help@symplifysolutions.com',
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, ResourceTopic topic) {
    if (onOpenResource != null) {
      onOpenResource!(topic);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ResourceScreen(topic: topic)),
    );
  }
}

/// Full-page presentation of the same body rendered by [ResourceContent].
class ResourceScreen extends StatelessWidget {
  const ResourceScreen({
    required this.topic,
    this.onBack,
    this.onOpenResource,
    super.key,
  });

  final ResourceTopic topic;
  final VoidCallback? onBack;
  final ValueChanged<ResourceTopic>? onOpenResource;

  @override
  Widget build(BuildContext context) {
    final article = resourceArticle(topic);
    return _ResourcePage(
      onBack: onBack,
      child: ResourceReadingWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),
            ResourceContent(topic: topic),
            if (article.relatedTopics.isNotEmpty) ...[
              const SizedBox(height: 36),
              const ResourceHeading('KEEP EXPLORING'),
              const SizedBox(height: 12),
              for (final related in article.relatedTopics) ...[
                const Divider(height: 1),
                ResourceListTile(
                  article: resourceArticle(related),
                  onTap: () {
                    if (onOpenResource != null) {
                      onOpenResource!(related);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ResourceScreen(topic: related),
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ResourcePage extends StatelessWidget {
  const _ResourcePage({required this.child, this.onBack});

  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (onBack != null || Navigator.of(context).canPop())
                    BackButton(onPressed: onBack),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Help and resources',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}
