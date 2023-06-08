import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/entry.dart';

final questionsProvider = Provider<QuestionRepo>((ref) {
  AuthUser user = ref.watch(currentAuthProvider);
  return ref.watch(reposProvider).questions(user: user);
});

final questionHomeProvider = StateProvider((ref) => QuestionNotifier(ref));

class QuestionNotifier extends StateNotifier {
  QuestionRepo? home;

  QuestionNotifier(StateProviderRef ref) : super(null) {
    _loadQuestions(ref);
  }

  _loadQuestions(StateProviderRef ref) async {
    home = ref.watch(questionsProvider);
    state = home;
  }
}
