import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';

import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class AddEvent extends ConsumerWidget {
  const AddEvent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    openEventOverlay(WidgetRef ref, DateTime addTime) {
      showDialog(
          context: context,
          builder: (context) => QuestionTypeOverlay(date: addTime));
    }

    final DateTime now = DateTime.now();

    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () {
        openEventOverlay(ref, now);
      },
    );
  }
}

class QuestionTypeOverlay extends ConsumerWidget {
  final DateTime date;

  const QuestionTypeOverlay({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final AsyncValue<List<RecordPath>> paths = ref.watch(recordPaths(
        const RecordPathProps(
            filterEnabled: true, type: PathProviderType.both)));

    final double screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 350, maxHeight: screenHeight / 2),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.small),
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
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            Icons.close,
                          )),
                    ]),
                AsyncValueDefaults(
                    value: paths,
                    onData: (recordPaths) {
                      final List<RecordPath> translatedPaths = recordPaths
                          .map((path) =>
                              localizations?.translatePath(path) ?? path)
                          .toList();
                      return Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...translatedPaths.mapIndexed(
                                (index, path) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppPadding.tiny),
                                  child: FilledButton(
                                    child: Text(path.name),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      context.pushNamed(
                                        'recordType',
                                        pathParameters: {
                                          'type': recordPaths[index].name
                                        },
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
