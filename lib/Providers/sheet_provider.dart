import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final StateProvider<bool> isSheetOpenProvider =
    StateProvider<bool>((ref) => false);

final Provider<ScrollController> historyScrollControllerProvider =
    Provider<ScrollController>((ref) {
  final ScrollController controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

final StateProvider<VoidCallback?> sheetCloseCallbackProvider =
    StateProvider<VoidCallback?>((ref) => null);
