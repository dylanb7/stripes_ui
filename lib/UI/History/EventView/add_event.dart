import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/History/EventView/events_calendar.dart';

import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/Util/extensions.dart';

class AddEvent extends ConsumerWidget {
  const AddEvent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    openEventOverlay(WidgetRef ref, DateTime addTime) {
      ref.read(overlayProvider.notifier).state =
          CurrentOverlay(widget: QuestionTypeOverlay(date: addTime));
    }

    final CalendarSelection calendarSelection = ref
        .watch(filtersProvider.select((filters) => filters.calendarSelection));

    final DateTime? selected = calendarSelection.selectedDate ??
        (calendarSelection.rangeEnd == null
            ? calendarSelection.rangeStart
            : null);

    final DateTime now = DateTime.now();

    return Tooltip(
      message: calendarSelection.selectedDate == null
          ? context.translate.noDateToAddTo
          : dateToMDY(calendarSelection.selectedDate!, context),
      child: IconButton(
        icon: const Icon(Icons.add),
        onPressed: selected == null
            ? null
            : () {
                openEventOverlay(
                    ref,
                    sameDay(now, selected)
                        ? now
                        : DateTime(
                            selected.year, selected.month, selected.day, 12));
              },
      ),
    );
  }
}

class QuestionTypeOverlay extends ConsumerWidget {
  final DateTime date;

  const QuestionTypeOverlay({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecordPath>> paths = ref.watch(recordPaths(
        const RecordPathProps(
            filterEnabled: true, type: PathProviderType.both)));
    return OverlayBackdrop(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: Theme.of(context).iconTheme.size),
                      Text(
                        context.translate.addEventHeader,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                          onPressed: () {
                            ref.read(overlayProvider.notifier).state =
                                closedOverlay;
                          },
                          icon: const Icon(
                            Icons.close,
                          )),
                    ]),
                AsyncValueDefaults(
                    value: paths,
                    onData: (recordPaths) {
                      return Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...recordPaths.map(
                                (path) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2.0),
                                  child: FilledButton(
                                    child: Text(path.name),
                                    onPressed: () {
                                      ref.read(overlayProvider.notifier).state =
                                          closedOverlay;
                                      context.pushNamed(
                                        'recordType',
                                        pathParameters: {'type': path.name},
                                        extra:
                                            QuestionsListener(submitTime: date),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })
              ],
            ),
          ),
        ),
      ),
    );
  }
}
