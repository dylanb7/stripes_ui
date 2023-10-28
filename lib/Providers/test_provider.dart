import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/base_stamp_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/bm_test_log.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/base_test_repo.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/entry.dart';

final testProvider = Provider<TestRepo<BlueDyeTest>?>((ref) {
  final StampRepo? repo = ref.watch(stampProvider);
  final SubUser sub =
      ref.watch(subHolderProvider.select((value) => value.current));
  final QuestionRepo questions = ref.watch(questionsProvider);
  if (repo == null) return null;
  return ref.watch(reposProvider).test(
      user: repo.authUser,
      subUser: sub,
      stampRepo: repo,
      questionRepo: questions);
});

final testHolderProvider = ChangeNotifierProvider<TestNotifier>(
  (ref) => TestNotifier(ref.read(testProvider)),
);

class TestNotifier extends ChangeNotifier with EquatableMixin {
  final TestRepo<BlueDyeTest>? repo;
  BlueDyeTest? obj;

  TestNotifier(this.repo) {
    if (repo != null) {
      repo!.obj.listen((event) {
        obj = event;
        notifyListeners();
      });
    }
  }

  Future<void> setStart(DateTime start) async {
    if (available && obj != null) {
      obj!.setStart = start;
    } else {
      obj = BlueDyeTest(startTime: start, logs: []);
    }
    await repo!.setValue(obj!);
  }

  Future<void> setDuration(Duration dur) async {
    if (!available) return;
    obj!.finished = dur;
    await repo!.setValue(obj!);
  }

  Future<void> addLog(BMTestLog log) async {
    if (!available) return;
    obj!.addLog(log);
    await repo!.setValue(obj!);
  }

  Future<void> submit(DateTime submitTime) async {
    if (!available) return;
    await repo!.submit(submitTime);
  }

  Future<void> cancel() async {
    if (!available) return;
    await repo!.cancel();
  }

  TestState get state => stateFromTestOBJ(obj);

  bool get available => repo != null;

  @override
  List<Object?> get props => [repo, obj];
}

enum TestState {
  initial,
  started,
  logs,
  logsSubmit;

  bool get testInProgress => this != TestState.initial;
}

TestState stateFromTestOBJ(BlueDyeTest? obj) {
  if (obj == null) return TestState.initial;
  if (obj.finishedEating == null) return TestState.started;
  bool startsBlue = false;
  bool endsNormal = false;
  for (BMTestLog log in obj.logs) {
    if (log.isBlue) {
      startsBlue = true;
    } else if (startsBlue) {
      endsNormal = true;
    }
  }
  if (endsNormal) return TestState.logsSubmit;
  return TestState.logs;
}
