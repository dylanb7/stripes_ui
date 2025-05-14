import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/History/EventView/add_event.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

enum FABType { scrollToTop, addEvent }

@immutable
class FabState {
  final Widget? fab;
  final FloatingActionButtonLocation? location;
  const FabState({required this.fab, this.location});
}

class AddEventFAB extends ConsumerWidget {
  const AddEventFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CalendarSelection calendarSelection = ref
        .watch(filtersProvider.select((filters) => filters.calendarSelection));

    final DateTime? selected = calendarSelection.selectedDate ??
        (calendarSelection.rangeEnd == null
            ? calendarSelection.rangeStart
            : null);
    return FloatingActionButton.extended(
      onPressed: () {
        ref.watch(overlayProvider.notifier).state = CurrentOverlay(
            widget: QuestionTypeOverlay(
          date: selected ?? DateTime.now(),
        ));
      },
      label: Text(AppLocalizations.of(context)!.addEventButton),
      icon: const Icon(Icons.add),
    );
  }
}
