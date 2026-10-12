/// Stable identifiers shared by resource routes and contextual help.
enum ResourceTopic {
  blueMealStudy('blue-meal-study'),
  blueMealAtHome('blue-meal-at-home'),
  bristolScale('bristol-scale'),
  symptomTracking('symptom-tracking'),
  bluePoop('bluepoop'),
  termsOfService('terms-of-service');

  const ResourceTopic(this.slug);

  final String slug;

  static ResourceTopic? fromSlug(String slug) {
    for (final topic in values) {
      if (topic.slug == slug) return topic;
    }
    return null;
  }
}

/// Content independent of whether it is shown on a page or in a help sheet.
class ResourceArticle {
  const ResourceArticle({
    required this.topic,
    required this.title,
    required this.summary,
    required this.description,
    required this.sections,
    this.relatedTopics = const [],
  });

  final ResourceTopic topic;
  final String title;
  final String summary;
  final String description;
  final List<ResourceSection> sections;
  final List<ResourceTopic> relatedTopics;
}

/// An addressable part of a guide that can also stand alone as contextual help.
class ResourceSection {
  const ResourceSection({
    required this.id,
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
    this.steps = const [],
    this.showBristolScale = false,
    this.links = const [],
    this.markdown,
    this.initiallyExpanded = false,
  });

  final String id;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<ResourceStep> steps;
  final bool showBristolScale;
  final List<ResourceLink> links;
  final String? markdown;
  final bool initiallyExpanded;
}

class ResourceStep {
  const ResourceStep({required this.title, required this.description});

  final String title;
  final String description;
}

class ResourceLink {
  const ResourceLink({required this.label, required this.url});

  final String label;
  final String url;
}
