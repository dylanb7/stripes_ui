import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';

class DraftRecordFlowSection {
  final String id;
  final List<Question> questions;
  String? header;
  DependsOn dependsOn = const DependsOn.nothing();

  DraftRecordFlowSection({required this.id, List<Question>? questions})
    : questions = questions ?? [];
}

class RecordFlowDraft {
  final List<DraftRecordFlowSection> sections = [];
  int _nextSectionId = 0;

  RecordFlowDraft() {
    addSection();
  }

  List<Question> get questions =>
      sections.expand((section) => section.questions).toList(growable: false);

  DraftRecordFlowSection addSection() {
    final section = DraftRecordFlowSection(
      id: 'draft-section-${DateTime.now().microsecondsSinceEpoch}-${_nextSectionId++}',
    );
    sections.add(section);
    return section;
  }

  void removeSection(DraftRecordFlowSection section) {
    sections.remove(section);
  }

  void moveSection(int from, int to) {
    final section = sections.removeAt(from);
    sections.insert(to, section);
  }

  void addQuestion(String sectionId, Question question) {
    final target = sections.firstWhere(
      (section) => section.id == sectionId,
      orElse: () => sections.first,
    );
    target.questions.add(question);
  }

  void deleteQuestion(DraftRecordFlowSection section, int questionIndex) {
    section.questions.removeAt(questionIndex);
  }

  void moveQuestion(
    Question question,
    DraftRecordFlowSection source,
    String targetId,
  ) {
    final target = sections.firstWhere((section) => section.id == targetId);
    source.questions.remove(question);
    target.questions.add(question);
  }

  void reorderQuestion(DraftRecordFlowSection section, int from, int to) {
    if (from < 0 ||
        from >= section.questions.length ||
        to < 0 ||
        to >= section.questions.length) {
      return;
    }
    final question = section.questions.removeAt(from);
    section.questions.insert(to, question);
  }

  bool get rulesFollowFlowOrder {
    final availableIds = <String>{};
    for (final section in sections) {
      if (!_conditionIds(section.dependsOn.groups)
          .every(availableIds.contains)) {
        return false;
      }
      for (final question in section.questions) {
        if (!_conditionIds(question.dependsOn?.groups ?? const [])
            .every(availableIds.contains)) {
          return false;
        }
        availableIds.add(question.id);
      }
    }
    return true;
  }

  Map<String, List<Question>> get availableDependenciesBySection {
    final result = <String, List<Question>>{};
    final previous = <Question>[];
    for (final section in sections) {
      result[section.id] = List.unmodifiable([
        ...previous,
        ...section.questions,
      ]);
      previous.addAll(section.questions);
    }
    return result;
  }

  List<Question> questionsBeforeSection(int sectionIndex) => sections
      .take(sectionIndex)
      .expand((section) => section.questions)
      .toList(growable: false);

  List<Question> questionsForType(String type) => questions
      .map(
        (question) => switch (question) {
          Check() => question.copyWith(type: type),
          Numeric() => question.copyWith(type: type),
          MultipleChoice() => question.copyWith(type: type),
          AllThatApply() => question.copyWith(type: type),
          FreeResponse() => question.copyWith(type: type),
        },
      )
      .toList();

  List<PageLayout> toPageLayouts() => sections
      .map(
        (section) => PageLayout(
          uid: section.id,
          header: section.header?.trim().isEmpty ?? true
              ? null
              : section.header!.trim(),
          questionIds: section.questions
              .map((question) => question.id)
              .toList(),
          dependsOn: section.dependsOn,
        ),
      )
      .toList();

  Iterable<String> _conditionIds(Iterable<ConditionGroup> groups) sync* {
    for (final group in groups) {
      for (final condition in group.conditions) {
        if (condition is ConditionGroup) {
          yield* _conditionIds([condition]);
        } else if (condition.questionId case final id?) {
          yield id;
        }
      }
    }
  }
}
