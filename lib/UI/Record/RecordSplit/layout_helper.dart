import 'package:flutter/widgets.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';

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
}
