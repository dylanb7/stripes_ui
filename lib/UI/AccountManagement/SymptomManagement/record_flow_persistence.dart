import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';

/// Persists a new record flow without ever publishing an empty intermediate
/// layout. Questions are written first because they do not require an existing
/// path; the complete path is then committed in one operation.
Future<bool> persistNewRecordFlow({
  required QuestionRepo repo,
  required RecordPath path,
  required List<Question> questions,
}) async {
  final addedQuestions = <Question>[];
  var pathAdded = false;
  var succeeded = true;

  try {
    for (final question in questions) {
      if (!await repo.addQuestion(question)) {
        succeeded = false;
        break;
      }
      addedQuestions.add(question);
    }
    if (succeeded) {
      pathAdded = await repo.addRecordPath(path);
      succeeded = pathAdded;
    }
  } catch (_) {
    succeeded = false;
  }

  if (succeeded) return true;

  for (final question in addedQuestions.reversed) {
    try {
      await repo.removeQuestion(question);
    } catch (_) {
      // Rollback is best-effort; preserve the original save failure.
    }
  }
  if (pathAdded) {
    try {
      await repo.removeRecordPath(path);
    } catch (_) {
      // Rollback is best-effort; preserve the original save failure.
    }
  }
  return false;
}
