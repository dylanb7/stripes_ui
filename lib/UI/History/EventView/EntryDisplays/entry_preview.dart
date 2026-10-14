import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

/// A small sample of the answers actually saved with an entry.
///
/// Question/choice localization is supplied by the caller. Free text is never
/// translated, numeric units are never inferred, and missing/invalid answers
/// are omitted rather than interpreted as an explicit negative answer.
List<String> entryPreviewDetails(
  Response entry, {
  required String selectedLabel,
  required String descriptionLabel,
  required String notSureLabel,
  Question Function(Question question)? translateQuestion,
  String? locale,
}) {
  final answers = <String>[];
  final notes = <String>[];
  final numberSymbols = NumberFormat.decimalPattern(locale).symbols;

  String numberLabel(num value) {
    // Preserve the stored value's precision. NumberFormat's fractional rounding
    // would change a saved answer, and very large fraction limits can overflow.
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

  // Keep user-authored prose concise without cutting a grapheme in half. The
  // complete saved text remains available in the expanded entry.
  String excerpt(String value) {
    final text = normalized(value);
    return text.characters.length <= 100
        ? text
        : '${text.characters.take(100)}…';
  }

  void collect(Response response) {
    if (response is UnresolvedResponse) return;
    if (response is DetailResponse) {
      final description = normalized(response.description ?? '');
      if (description.isNotEmpty) {
        notes.add('$descriptionLabel: ${excerpt(description)}');
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
    // A generated question without its resolved wording is not a useful or
    // trustworthy label. Leave it to the full detail renderer to resolve it.
    if (prompt.isEmpty || prompt.contains(RegExp(r'\{[^}]+\}'))) return;

    final String value;
    switch (response) {
      case OpenResponse():
        value = excerpt(response.response);
      case NumericResponse():
        if (!response.response.isFinite) return;
        final isPain = question.id == 'Pain-Rating' || question.id == 'q6';
        value = isPain && response.response == -1
            ? notSureLabel
            : numberLabel(response.response);
      case Selected():
        value = selectedLabel;
      case MultiResponse():
        if (question is! MultipleChoice ||
            response.index < 0 ||
            response.index >= question.choices.length) {
          return;
        }
        value = normalized(question.choices[response.index]);
      case AllResponse():
        if (question is! AllThatApply) return;
        final choices = response.responses
            .where((index) => index >= 0 && index < question.choices.length)
            .map((index) => normalized(question.choices[index]))
            .where((choice) => choice.isNotEmpty)
            .toSet()
            .toList();
        // Show a sample without implying that the complete selection is shown.
        value = choices.length > 3
            ? '${choices.take(3).join(', ')}…'
            : choices.join(', ');
      case UnresolvedResponse() || ResponseWrap() || SingleResponseWrap():
        return;
    }
    if (value.isNotEmpty) answers.add('$prompt: $value');
  }

  collect(entry);
  final distinctAnswers = answers.toSet().toList();
  // A personal note is often the best way to recognize a particular entry.
  // Reserve one of the two preview details for it when one was recorded.
  return List.unmodifiable([
    ...distinctAnswers.take(notes.isEmpty ? 2 : 1),
    if (notes.isNotEmpty) notes.first,
  ]);
}
