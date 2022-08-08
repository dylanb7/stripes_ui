import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/base_stamp_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/base_test_repo.dart';

import 'package:stripes_ui/Providers/repos_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';

final testProvider = Provider<TestRepo<BlueDyeTest>?>((ref) {
  final StampRepo? repo = ref.watch(stampProvider);
  if (repo == null) return null;
  return ref
      .watch(reposProvider)
      .test(user: repo.authUser, subUser: repo.currentUser, stampRepo: repo);
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
        obj = event as BlueDyeTest;
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
