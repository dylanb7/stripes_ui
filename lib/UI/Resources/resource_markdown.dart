import 'package:flutter/material.dart';
import 'package:markdown_widget/config/markdown_generator.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:stripes_ui/Util/extensions.dart';

/// Applies reading size once, including inside nested Markdown lists.
///
/// markdown_widget nests rich text inside WidgetSpans. Letting Text scale those
/// spans scales their constraints again at every list level. Scale the text
/// styles explicitly and leave widget geometry at its natural size instead.
class ResourceMarkdown extends StatelessWidget {
  const ResourceMarkdown({required this.data, super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    return MarkdownBlock(
      data: data,
      config: context.markdownConfig,
      generator: MarkdownGenerator(
        richTextBuilder: (span) => Text.rich(
          _scaleSpan(span, scaler),
          style: baseStyle.copyWith(
            fontSize: scaler.scale(baseStyle.fontSize!),
          ),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }

  InlineSpan _scaleSpan(InlineSpan span, TextScaler scaler) {
    if (span is! TextSpan) return span;
    final fontSize = span.style?.fontSize;
    return TextSpan(
      text: span.text,
      style: fontSize == null
          ? span.style
          : span.style!.copyWith(fontSize: scaler.scale(fontSize)),
      children: span.children
          ?.map((child) => _scaleSpan(child, scaler))
          .toList(),
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
}
