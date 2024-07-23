import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';

import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class AddEvent extends ConsumerWidget {
  const AddEvent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    openEventOverlay(WidgetRef ref, DateTime addTime) {
      ref.read(overlayProvider.notifier).state =
          CurrentOverlay(widget: _QuestionTypeOverlay(date: addTime));
    }

    final Filters filters = ref.watch(filtersProvider);

    final DateTime? selected = filters.selectedDate ??
        (filters.rangeEnd == null ? filters.rangeStart : null);

    return Tooltip(
      message: filters.selectedDate == null
          ? AppLocalizations.of(context)!.noDateToAddTo
          : dateToMDY(filters.selectedDate!, context),
      child: IconButton(
        icon: const Icon(Icons.add),
        onPressed: selected == null
            ? null
            : () {
                openEventOverlay(ref,
                    DateTime(selected.year, selected.month, selected.day, 12));
              },
      ),
    );
  }
}

class _QuestionTypeOverlay extends ConsumerWidget {
  final DateTime date;

  const _QuestionTypeOverlay({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> questionTypes = ref
        .watch(questionSplitProvider(PageProps(context: context)))
        .keys
        .toList();
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
                      const SizedBox(width: 30),
                      Text(
                        AppLocalizations.of(context)!.addEventHeader,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      IconButton(
                          onPressed: () {
                            ref.read(overlayProvider.notifier).state =
                                closedQuery;
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 30,
                          )),
                    ]),
                ...questionTypes.map((type) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: FilledButton(
                        child: Text(type),
                        onPressed: () {
                          ref.read(overlayProvider.notifier).state =
                              closedQuery;
                          context.pushNamed(
                            'recordType',
                            pathParameters: {'type': type},
                            extra: QuestionsListener(submitTime: date),
                          );
                        },
                      ),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
