import 'package:csv/csv.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

/// Shared schemas and CSV generation for the export preview and download.
abstract final class CsvExportData {
  static const detailColumns = [
    'id',
    'date',
    'group',
    'category',
    'prompt',
    'response',
    'description',
  ];

  static const transitColumns = [
    'ID',
    'Amount Consumed',
    'Test Start',
    'Eating Duration',
    'Finished Eating',
    'Transit Duration',
    'Lag Phase',
    'BM Date',
    'BMID',
    'Description',
    'Is Blue',
    'Prompt',
    'Response',
  ];

  static String formatResponse(
    Response response, [
    QuestionsLocalizations? questionsL10n,
  ]) {
    if (response is UnresolvedResponse) {
      return 'Unresolved: ${response.raw}';
    }
    String localize(String key) => questionsL10n?.value(key) ?? key;

    if (response is NumericResponse) {
      return '${response.response}';
    }
    if (response is OpenResponse) {
      return response.response;
    }
    if (response is MultiResponse) {
      if (response.index < response.question.choices.length) {
        return localize(response.question.choices[response.index]);
      }
      return 'Unknown';
    }
    if (response is AllResponse) {
      return response.choices.map((c) => localize(c)).join(', ');
    }
    return 'Selected';
  }

  static String generateDetailCsv(
    List<DetailResponse> responses,
    QuestionsLocalizations? questionsL10n,
  ) {
    final rows = <List<dynamic>>[detailColumns];

    String localize(String key) => questionsL10n?.value(key) ?? key;

    for (final detail in responses) {
      final date = dateFromStamp(detail.stamp);
      final dateStr = date.toUtc().toIso8601String();
      for (final r in detail.responses) {
        rows.add([
          detail.id ?? '',
          dateStr,
          detail.group != null ? localize(detail.group!) : '',
          localize(r.type),
          localize(r.question.prompt),
          formatResponse(r, questionsL10n),
          detail.description ?? '',
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  static String generateBlueDyeCsv(
    List<BlueDyeResp> responses, {
    QuestionsLocalizations? questionsL10n,
  }) {
    final rows = <List<dynamic>>[transitColumns];

    String localize(String key) => questionsL10n?.value(key) ?? key;

    for (final resp in responses) {
      // Correct calculations:
      // Transit Duration = time from START of eating to first blue BM
      final transitDuration = resp.firstBlue.difference(resp.startEating);
      // Lag Phase = time from first blue BM to last blue BM
      final lagPhase = resp.lastBlue.difference(resp.firstBlue);

      // One row per response within each BM log (nested: Test -> Log -> Response)
      for (final log in resp.logs) {
        final bmDate = dateFromStamp(log.stamp);

        for (final logResponse in log.response.responses) {
          String prompt = localize(logResponse.question.prompt);
          String responseValue = '';

          if (logResponse is UnresolvedResponse) {
            responseValue = 'Unresolved: ${logResponse.raw}';
          } else if (logResponse is NumericResponse) {
            responseValue = '${logResponse.response}';
          } else if (logResponse is OpenResponse) {
            responseValue = logResponse.response;
          } else if (logResponse is MultiResponse &&
              logResponse.index < logResponse.question.choices.length) {
            responseValue = localize(
              logResponse.question.choices[logResponse.index],
            );
          } else if (logResponse is AllResponse) {
            responseValue = logResponse.choices
                .map((c) => localize(c))
                .join(', ');
          }

          rows.add([
            resp.id ?? '',
            resp.amountConsumed.name,
            resp.startEating.toUtc().toIso8601String(),
            _eatingDurationMinutes(resp.eatingDuration),
            resp.finishedEatingTime?.toUtc().toIso8601String() ?? '',
            transitDuration.inMinutes,
            lagPhase.inMinutes,
            bmDate.toUtc().toIso8601String(),
            log.id ?? '',
            log.response.description ?? '',
            log.isBlue ? 'true' : 'false',
            prompt,
            responseValue,
          ]);
        }
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  static Object _eatingDurationMinutes(Duration duration) {
    // Zero marks a tube feeding with no recorded duration.
    if (duration == Duration.zero) return '';
    if (duration.inMicroseconds % Duration.microsecondsPerMinute == 0) {
      return duration.inMinutes;
    }
    return duration.inMicroseconds / Duration.microsecondsPerMinute;
  }
}
