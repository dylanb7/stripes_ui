import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/base_sub_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/Services/shared_service.dart';

final subProvider = FutureProvider<SubUserRepo?>((ref) async {
  final auth = await ref.watch(authStream.future);
  return AuthUser.isEmpty(auth)
      ? null
      : ref.watch(reposProvider).sub(user: auth);
});

final subStream = StreamProvider<List<SubUser>>((ref) async* {
  final SubUserRepo? repo = await ref.watch(subProvider.future);
  if (repo == null) {
    yield const <SubUser>[];
    return;
  }
  yield* repo.users;
});

final subHolderProvider = AsyncNotifierProvider<SubNotifier, SubState>(
  SubNotifier.new,
);

class SubNotifier extends AsyncNotifier<SubState> {
  @override
  FutureOr<SubState> build() async {
    final SharedService service = ref.watch(sharedSeviceProvider);
    final List<SubUser> subUsers = await ref.watch(subStream.future);
    if (subUsers.isEmpty) {
      return SubState.empty();
    }
    final String? currentId = await service.getCurrentUser();
    final SubUser? currentUser = subUsers.firstWhereOrNull(
      (element) => element.uid == currentId,
    );
    if (currentId == null || currentUser == null) {
      final SubUser newSelected = subUsers.first;
      await service.setCurrentUser(id: newSelected.uid);
      return SubState(subUsers: subUsers, selected: newSelected);
    }
    return SubState(subUsers: subUsers, selected: currentUser);
  }

  Future<bool> changeCurrent(SubUser newUser) async {
    final SubState current = await future;
    final SubUser? changedTo = current.subUsers.firstWhereOrNull(
      (user) => user.uid == newUser.uid,
    );
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
class SubState with Equatable {
  final List<SubUser> subUsers;
  final SubUser? selected;

  SubState({required this.subUsers, this.selected});

  factory SubState.empty() => SubState(subUsers: const []);

  SubState copyWith({List<SubUser>? subUsers, SubUser? selected}) => SubState(
    subUsers: subUsers ?? this.subUsers,
    selected: selected ?? this.selected,
  );

  @override
  List<Object?> get props => [subUsers, selected];
}

final onboardingCompleteProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

class OnboardingNotifier extends AsyncNotifier<bool> {
  String? _accountId;
  bool? _completed;

  void complete() {
    _completed = true;
    state = const AsyncValue.data(true);
  }

  void reset() {
    _completed = false;
    state = const AsyncValue.data(false);
  }

  @override
  FutureOr<bool> build() async {
    final buildRef = ref;
    final accountFuture = buildRef.watch(authStream.future);
    final profilesFuture = buildRef.watch(subHolderProvider.future);
    final account = await accountFuture;
    final SubState subState = await profilesFuture;
    if (!buildRef.mounted) return false;

    if (_accountId != account.uid) {
      _accountId = account.uid;
      _completed = null;
    }

    final SubUser? selected = subState.selected;
    final bool alreadyHasUser = selected != null && !SubUser.isEmpty(selected);
    // Existing profiles skip first-time setup, but selecting a newly created
    // profile must not dismiss its baselines and overview before complete().
    if (!alreadyHasUser) _completed = false;
    return _completed ??= alreadyHasUser;
  }
}
