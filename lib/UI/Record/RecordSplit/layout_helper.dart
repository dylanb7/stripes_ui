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

    // First filter pages by page-level dependsOn
    final pagesWithDependsOn =
        loadedLayouts.where((page) => page.dependsOn.eval(listener)).toList();

    // Then filter questions within each page
    final List<LoadedPageLayout> filteredLayouts = [];
    final List<Question> allHiddenQuestions = [];

    for (final page in pagesWithDependsOn) {
      final List<Question> visibleQuestions = [];
      final List<Question> hiddenQuestions = [];

      for (final question in page.questions) {
        // If a whitelist is provided, only show questions in the list
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

      // Only add page if it has visible questions
      if (visibleQuestions.isNotEmpty) {
        filteredLayouts.add(page.copyWith(questions: visibleQuestions));
      }
    }

    // Cleanup: Remove data for hidden questions
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

  /// Validates page at the given index, returning pending count and requirement status.
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

    final pageQuestions = pages[currentIndex].questions;
    final pendingCount = listener.pending
        .where((pending) => pageQuestions.contains(pending))
        .length;

    final requirement = pages[currentIndex].requirement;
    final requirementMet = requirement.eval(listener);

    return PageValidation(
      pendingCount: pendingCount,
      requirementMet: requirementMet,
      pendingRequirement: requirementMet ? null : requirement,
    );
  }

  /// Calculates question progress for the current page.
  static QuestionProgress calculateProgress({
    required List<LoadedPageLayout> pages,
    required int currentIndex,
    required QuestionsListener listener,
  }) {
    if (currentIndex >= pages.length) {
      return const QuestionProgress(total: 0, answered: 0, pendingRequired: 0);
    }

    final pageQuestions = pages[currentIndex].questions;

    final visibleQuestions = pageQuestions.where((q) {
      return q.dependsOn == null || q.dependsOn!.eval(listener);
    }).toList();

    final pageQuestionIds = visibleQuestions.map((q) => q.id).toSet();

    // Helper to check if a question ID belongs to this page
    // Generated questions have IDs like "sourceId::index"
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

  /// Resolves a question ID to its prompt text for error messages.
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
}
