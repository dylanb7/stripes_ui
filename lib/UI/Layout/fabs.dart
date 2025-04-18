import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
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
    return FloatingActionButton.extended(
      onPressed: () {
        ref.watch(overlayProvider.notifier).state =
            const CurrentOverlay(widget: _QuestionTypeOverlay());
      },
      label: Text(AppLocalizations.of(context)!.addEventButton),
      icon: const Icon(Icons.add),
    );
  }
}

class _QuestionTypeOverlay extends ConsumerWidget {
  const _QuestionTypeOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime? date = ref.watch(filtersProvider
        .select((value) => value.calendarSelection.selectedDate));
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
                                closedOverlay;
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
                              closedOverlay;
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
