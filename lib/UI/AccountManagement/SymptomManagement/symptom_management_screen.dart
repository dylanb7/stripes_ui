import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/Util/constants.dart';

class SymptomManagementScreen extends ConsumerWidget {
  const SymptomManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, RecordPath> recordPaths =
        ref.watch(recordProvider(PageProps(context: context)));
    final Map<Period, List<CheckinItem>> checkin =
        ref.watch(checkinProvider(CheckInProps(context: context)));

    return RefreshWidget(
      depth: RefreshDepth.subuser,
      scrollable: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 20.0,
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      context.goNamed(Routes.ACCOUNT);
                    },
                    icon: const Icon(Icons.keyboard_arrow_left)),
                Text(
                  'Symptoms',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.left,
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(
              height: 6.0,
            ),
            const Text("Categories"),
            ...recordPaths.keys.map((key) {
              final RecordPath path = recordPaths[key]!;
              final int symptoms = path.pages.isEmpty ? 0 : path.pages.map((page) => page.questionIds.length).reduce((value, element) => value + element)
              return ListTile(
                title: Text(key),
                subtitle: Text(
                    "Symptoms: $symptoms}"),
              );
            }),
            /*
            ...checkin.keys.map((items) {
              items.map((item) => {
                item.
              });
              return Container();
            })*/
          ],
        ),
      ),
    );
  }
}
