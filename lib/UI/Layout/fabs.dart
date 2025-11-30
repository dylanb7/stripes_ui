import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/History/EventView/add_event.dart';
import 'package:stripes_ui/Util/extensions.dart';

enum FABType { scrollToTop, addEvent }

@immutable
class FabState {
  final Widget? fab;
  final FloatingActionButtonLocation? location;
  const FabState({required this.fab, this.location});
}
