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

final subProvider = Provider<SubUserRepo?>(
  (ref) {
    final auth = ref.watch(currentAuthProvider);
    return AuthUser.isEmpty(auth)
        ? null
        : ref.watch(reposProvider).sub(user: auth);
  },
);

final subHolderProvider = ChangeNotifierProvider<SubNotifier>((ref) {
  final sub = ref.watch(subProvider);
  final shared = ref.watch(sharedSeviceProvider);
  return SubNotifier(sub, shared);
});

class SubNotifier extends ChangeNotifier with EquatableMixin {
  final SubUserRepo? ref;
  final SharedService service;
  List<SubUser> _values = [];
  bool _isLoading = false;
  SubUser _current = SubUser.empty();

  SubNotifier(this.ref, this.service) {
    if (ref != null) {
      ref!.users.listen((event) async {
        _values = event;
        await _setUpCurrent();
        notifyListeners();
      });
    }
  }

  Future<bool> changeCurrent(SubUser newUser) async {
    if (!_values.contains(newUser)) return false;
    String? val = await service.getCurrentUser();
    if (val == newUser.uid) return true;
    final bool set = await service.setCurrentUser(id: newUser.uid);
    if (set) {
      _current = newUser;
      notifyListeners();
    }
    return set;
  }

  Future<void> _setUpCurrent() async {
    if (_values.isEmpty) {
      _current = SubUser.empty();
      return;
    }
    _isLoading = true;
    String? user = await service.getCurrentUser();
    List<SubUser> selected =
        _values.where((element) => user == element.uid).toList(growable: false);
    if (user != null && selected.isNotEmpty) {
      _current = selected.first;
      _isLoading = false;
      return;
    }
    final SubUser toSet = _values.first;
    bool set = await service.setCurrentUser(id: toSet.uid);
    if (set) _current = toSet;
    _isLoading = false;
  }

  SubUser get current => _current;

  List<SubUser> get users => _values;

  bool get isAvailable => ref != null;

  bool get isLoading => _isLoading;

  @override
  List<Object?> get props => [_current, _values];

  @override
  String toString() {
    return 'current($_current) | all($_values)';
  }
}
