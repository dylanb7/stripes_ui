import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

/// A compact visual sample with full question context for accessibility.
class EntryPreviewDetail {
  final String label;
  final String semanticsLabel;

  const EntryPreviewDetail(this.label, this.semanticsLabel);
}

class _PreviewCandidate {
  final EntryPreviewDetail detail;
  final int priority;
  final int order;
  final String? singleLabel;

  const _PreviewCandidate(
    this.detail,
    this.priority,
    this.order,
    this.singleLabel,
  );
}

/// Question metadata supplies concise labels and optional presentation order.
/// Lower priorities appear first; ties preserve saved answer order. This is
/// never severity-based. Each detail has its own text budget so a long prompt
/// cannot consume the entire preview. Older/custom questions need no metadata.
List<EntryPreviewDetail> entryPreviewDetails(
  Response entry, {
  required String selectedLabel,
  required String descriptionLabel,
  required String notSureLabel,
  Question Function(Question question)? translateQuestion,
  String Function(Question question)? translateShortPrompt,
  String? locale,
}) {
  final candidates = <_PreviewCandidate>[];
  final numberSymbols = NumberFormat.decimalPattern(locale).symbols;

  String numberLabel(num value) {
    // Preserve stored precision instead of rounding the saved answer.
    final text = value.toString().replaceFirst(RegExp(r'\.0$'), '');
    final zero = numberSymbols.ZERO_DIGIT.runes.single;
    return text
        .replaceAllMapped(
          RegExp(r'[0-9]'),
          (digit) => String.fromCharCode(zero + int.parse(digit[0]!)),
        )
        .replaceAll('.', numberSymbols.DECIMAL_SEP)
        .replaceAll('-', numberSymbols.MINUS_SIGN);
  }

  String normalized(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  String excerpt(String value, int limit) {
    final text = normalized(value);
    if (text.characters.length <= limit) return text;
    final prefix = text.characters.take(limit - 1).toString();
    final space = prefix.lastIndexOf(' ');
    final end = space > prefix.length * 0.65
        ? prefix.substring(0, space)
        : prefix;
    return '${end.trimRight()}…';
  }

  void add(
    String label,
    String semanticsLabel,
    int priority, {
    String? singleLabel,
  }) {
    if (candidates.any(
      (item) => item.detail.semanticsLabel == semanticsLabel,
    )) {
      return;
    }
    candidates.add(
      _PreviewCandidate(
        EntryPreviewDetail(label, semanticsLabel),
        priority,
        candidates.length,
        singleLabel,
      ),
    );
  }

  void collect(Response response) {
    if (response is UnresolvedResponse) return;
    if (response is DetailResponse) {
      final note = normalized(response.description ?? '');
      if (note.isNotEmpty) {
        add(
          '“${excerpt(note, 30)}”',
          '$descriptionLabel: ${excerpt(note, 100)}',
          50,
        );
      }
    }
    if (response is ResponseWrap) {
      for (final child in response.responses) {
        collect(child);
      }
      return;
    }
    if (response is SingleResponseWrap) {
      collect(response.response);
      return;
    }

    final question =
        translateQuestion?.call(response.question) ?? response.question;
    final prompt = normalized(question.prompt);
    if (prompt.isEmpty || prompt.contains(RegExp(r'\{[^}]+\}'))) return;
    final shorthand = normalized(
      translateShortPrompt?.call(response.question) ??
          question.shortPrompt ??
          '',
    );
    final shortLabel =
        shorthand.isEmpty ||
            shorthand == prompt ||
            shorthand.contains(RegExp(r'\{[^}]+\}'))
        ? null
        : shorthand;
    final priority =
        question.previewPriority ??
        (shortLabel != null || prompt.characters.length <= 24 ? 40 : 70);
    final String value;

    switch (response) {
      case OpenResponse():
        value = normalized(response.response);
      case NumericResponse():
        if (!response.response.isFinite) return;
        // Decode the existing pain control's stored 'Not sure' sentinel.
        // This affects answer text only, never preview labels or ranking.
        final isPain =
            !question.userCreated &&
            (question.id == 'Pain-Rating' || question.id == 'q6');
        value = isPain && response.response == -1
            ? notSureLabel
            : numberLabel(response.response);
      case Selected():
        // A checked symptom states the answer without the redundant Selected.
        add(
          excerpt(shortLabel ?? prompt, 34),
          '$prompt: $selectedLabel',
          priority,
        );
        return;
      case MultiResponse():
        if (question is! MultipleChoice ||
            response.index < 0 ||
            response.index >= question.choices.length) {
          return;
        }
        value = normalized(question.choices[response.index]);
      case AllResponse():
        if (question is! AllThatApply) return;
        value = response.responses
            .where((index) => index >= 0 && index < question.choices.length)
            .map((index) => normalized(question.choices[index]))
            .where((choice) => choice.isNotEmpty)
            .toSet()
            .join(', ');
      case UnresolvedResponse() || ResponseWrap() || SingleResponseWrap():
        return;
    }
    if (value.isEmpty) return;
    final label =
        '${excerpt(shortLabel ?? prompt, response is NumericResponse ? 20 : 16)}: '
        '${response is NumericResponse ? value : excerpt(value, 18)}';
    add(
      label,
      '$prompt: ${excerpt(value, 100)}',
      priority,
      // A single custom answer can use the spare space for the answer rather
      // than extending its question or leaving most of the preview empty.
      singleLabel: response is! NumericResponse && shortLabel == null
          ? '${excerpt(prompt, 16)}: ${excerpt(value, 44)}'
          : null,
    );
  }

  collect(entry);
  candidates.sort((a, b) {
    final priority = a.priority.compareTo(b.priority);
    return priority != 0 ? priority : a.order.compareTo(b.order);
  });
  final selected = candidates.take(2).toList();
  return List.unmodifiable(
    selected.map(
      (item) => selected.length == 1 && item.singleLabel != null
          ? EntryPreviewDetail(item.singleLabel!, item.detail.semanticsLabel)
          : item.detail,
    ),
  );
}
