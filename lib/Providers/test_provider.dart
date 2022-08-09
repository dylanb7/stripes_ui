import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/base_stamp_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/bm_test_log.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/base_test_repo.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/entry.dart';

final testProvider = Provider<TestRepo<BlueDyeTest>?>((ref) {
  final StampRepo? repo = ref.watch(stampProvider);
  final SubUser sub =
      ref.watch(subHolderProvider.select((value) => value.current));
  if (repo == null) return null;
  return ref
      .watch(reposProvider)
      .test(user: repo.authUser, subUser: sub, stampRepo: repo);
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

  setStart(DateTime start) {
    if (available) {
      obj!.setStart = start;
    } else {
      obj = BlueDyeTest(startTime: start, logs: []);
    }
    repo!.setValue(obj!);
  }

  setDuration(Duration dur) {
    if (!available) return;
    obj!.finished = dur;
    repo!.setValue(obj!);
  }

  submit(DateTime submitTime) {
    if (!available) return;
    repo!.submit(submitTime);
  }

  cancel() {
    if (!available) return;
    repo!.cancel();
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
