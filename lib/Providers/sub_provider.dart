import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/base_sub_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/Services/shared_service.dart';
import 'package:stripes_ui/entry.dart';

final subProvider = FutureProvider<SubUserRepo?>(
  (ref) async {
    final auth = await ref.watch(authStream.future);
    return AuthUser.isEmpty(auth)
        ? null
        : ref.watch(reposProvider).sub(user: auth);
  },
);

final subStream = StreamProvider<List<SubUser>>((ref) async* {
  final SubUserRepo? repo = await ref.watch(subProvider.future);
  if (repo == null) {
    yield [];
  } else {
    yield* repo.users;
  }
});

final subHolderProvider =
    AsyncNotifierProvider<SubNotifier, SubState>(SubNotifier.new);

class SubNotifier extends AsyncNotifier<SubState> {
  @override
  FutureOr<SubState> build() async {
    final SharedService service = ref.watch(sharedSeviceProvider);
    final List<SubUser> subUsers = await ref.watch(subStream.future);
    if (subUsers.isEmpty) return SubState.empty();
    final String? currentId = await service.getCurrentUser();
    final SubUser? currentUser =
        subUsers.firstWhereOrNull((element) => element.uid == currentId);
    if (currentId == null || currentUser == null) {
      final SubUser newSelected = subUsers.first;
      await service.setCurrentUser(id: newSelected.uid);
      return SubState(subUsers: subUsers, selected: newSelected);
    }
    return SubState(subUsers: subUsers, selected: currentUser);
  }

  Future<bool> changeCurrent(SubUser newUser) async {
    final SubState current = await future;
    final SubUser? changedTo =
        current.subUsers.firstWhereOrNull((user) => user.uid == newUser.uid);
    if (changedTo == null) return false;
    final SharedService service = ref.watch(sharedSeviceProvider);
    if (current.selected?.uid == changedTo.uid) return true;
    final bool setUser = await service.setCurrentUser(id: changedTo.uid);
    if (setUser) {
      state = AsyncData(current.copyWith(selected: changedTo));
    }
    return setUser;
  }
}

@immutable
class SubState with EquatableMixin {
  final List<SubUser> subUsers;
  final SubUser? selected;

  SubState({required this.subUsers, this.selected});

  factory SubState.empty() => SubState(subUsers: const []);

  SubState copyWith({List<SubUser>? subUsers, SubUser? selected}) => SubState(
      subUsers: subUsers ?? this.subUsers, selected: selected ?? this.selected);

  @override
  List<Object?> get props => [subUsers, selected];
}
