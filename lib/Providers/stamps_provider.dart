import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/base_stamp_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/entry.dart';

import 'auth_provider.dart';

final stampProvider = Provider<StampRepo?>((ref) {
  final auth = ref.watch(currentAuthProvider);
  final sub = ref.watch(subHolderProvider.select((value) => value.current));
  if (AuthUser.isEmpty(auth) || SubUser.isEmpty(sub)) return null;
  return ref.watch(reposProvider).stamp(user: auth, subUser: sub);
});

final stampHolderProvider = ChangeNotifierProvider<StampNotifier>(
    (ref) => StampNotifier(ref.watch(stampProvider)));

class StampNotifier extends ChangeNotifier {
  final StampRepo? stampRepo;
  List<Stamp> stamps = [];
  StampNotifier(this.stampRepo) {
    if (available) {
      stampRepo!.stamps.listen(_listen);
    }
  }

  _listen(List<Stamp> event) {
    stamps = event;
    if (hasListeners) notifyListeners();
  }

  changeEarliest(DateTime time) {
    stampRepo?.earliestDate = time;
  }

  @override
  String toString() {
    return stamps.map((e) => e.type).join(' ');
  }

  bool get available => stampRepo != null;
}
