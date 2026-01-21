import 'package:flutter/widgets.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/requirement.dart';

/// Result of evaluating page requirements and pending questions.
class PageValidation {
  final int pendingCount;
  final bool requirementMet;
  final Requirement? pendingRequirement;

  const PageValidation({
    required this.pendingCount,
    required this.requirementMet,
    this.pendingRequirement,
  });

  bool get canProceed => pendingCount == 0 && requirementMet;
}

/// Progress tracking for questions on a page.
class QuestionProgress {
  final int total;
  final int answered;
  final int pendingRequired;

  const QuestionProgress({
    required this.total,
    required this.answered,
    required this.pendingRequired,
  });

  double get percentage => total > 0 ? answered / total : 0;
}

class LayoutHelper {
  static List<LoadedPageLayout> processLayouts({
    required List<LoadedPageLayout>? loadedLayouts,
    required QuestionsListener listener,
    List<Question>? whiteList,
    bool deferCleanup = false,
  }) {
    if (loadedLayouts == null) return [];

    final List<LoadedPageLayout> visiblePages = [];
    final List<LoadedPageLayout> hiddenPages = [];

    // Separate visible and hidden pages based on page.dependsOn
    for (final page in loadedLayouts) {
      if (page.dependsOn.eval(listener)) {
        visiblePages.add(page);
      } else {
        hiddenPages.add(page);
      }
    }

    final List<LoadedPageLayout> filteredLayouts = [];
    final List<Question> allHiddenQuestions = [];

    // Collect all questions from hidden pages for cleanup
    for (final page in hiddenPages) {
      allHiddenQuestions.addAll(page.questions);
    }

    for (final page in visiblePages) {
      final List<Question> visibleQuestions = [];
      final List<Question> hiddenQuestions = [];

      for (final question in page.questions) {
        if (whiteList != null && !whiteList.any((q) => q.id == question.id)) {
          continue;
        }

        final bool shouldShow = question.dependsOn?.eval(listener) ?? true;

        if (shouldShow) {
          visibleQuestions.add(question);
        } else {
          hiddenQuestions.add(question);
        }
      }

      allHiddenQuestions.addAll(hiddenQuestions);

      if (visibleQuestions.isNotEmpty) {
        filteredLayouts.add(page.copyWith(questions: visibleQuestions));
      }
    }

    void performCleanup() {
      for (final question in allHiddenQuestions) {
        if (listener.fromQuestion(question) != null) {
          listener.removeResponse(question);
          listener.removePending(question);
        }
      }
    }

    if (deferCleanup && allHiddenQuestions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        performCleanup();
      });
    } else {
      performCleanup();
    }

    return filteredLayouts;
  }

  static PageValidation validatePage({
    required List<LoadedPageLayout> pages,
    required int currentIndex,
    required QuestionsListener listener,
  }) {
    if (currentIndex > pages.length - 1) {
      return const PageValidation(
        pendingCount: 0,
        requirementMet: true,
      );
    }

    final List<Question> pageQuestions = pages[currentIndex].questions;
    final int pendingCount = listener.pending
        .where((pending) => pageQuestions.contains(pending))
        .length;

    final Requirement requirement = pages[currentIndex].requirement;
    final bool requirementMet = requirement.eval(listener);

    return PageValidation(
      pendingCount: pendingCount,
      requirementMet: requirementMet,
      pendingRequirement: requirementMet ? null : requirement,
    );
  }

  static QuestionProgress calculateProgress({
    required List<LoadedPageLayout> pages,
    required int currentIndex,
    required QuestionsListener listener,
  }) {
    if (currentIndex >= pages.length) {
      return const QuestionProgress(total: 0, answered: 0, pendingRequired: 0);
    }

    final List<Question> pageQuestions = pages[currentIndex].questions;

    final List<Question> visibleQuestions = pageQuestions.where((q) {
      return q.dependsOn == null || q.dependsOn!.eval(listener);
    }).toList();

    final Set<String> pageQuestionIds =
        visibleQuestions.map((q) => q.id).toSet();

    bool belongsToPage(String questionId) {
      if (pageQuestionIds.contains(questionId)) return true;
      final parts = questionId.split('::');
      if (parts.length > 1) {
        return pageQuestionIds.contains(parts.first);
      }
      return false;
    }

    final answeredCount =
        listener.questions.keys.where((qId) => belongsToPage(qId)).length;
    final pendingRequiredCount =
        listener.pending.where((q) => belongsToPage(q.id)).length;

    return QuestionProgress(
      total: visibleQuestions.length,
      answered: answeredCount,
      pendingRequired: pendingRequiredCount,
    );
  }

  static String? resolveQuestionPrompt(
    String questionId,
    List<LoadedPageLayout> pages,
  ) {
    for (final page in pages) {
      try {
        final q = page.questions.firstWhere((q) => q.id == questionId);
        return q.prompt;
      } catch (_) {}
    }
    return null;
  }

  static PageValidation validateSubmitScreen({
    required List<Question> submitQuestions,
    required QuestionsListener listener,
  }) {
    if (submitQuestions.isEmpty) {
      return const PageValidation(
        pendingCount: 0,
        requirementMet: true,
      );
    }

    int unansweredCount = 0;
    for (final question in submitQuestions) {
      // Skip questions where dependsOn evaluates to false
      final bool shouldShow = question.dependsOn?.eval(listener) ?? true;
      if (!shouldShow) continue;

      final bool isRequired = question.requirement?.eval(listener) ?? true;
      if (isRequired) {
        final response = listener.fromQuestion(question);
        if (response == null) {
          unansweredCount++;
        }
      }
    }

    return PageValidation(
      pendingCount: unansweredCount,
      requirementMet: unansweredCount == 0,
    );
  }
}
