import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/extensions.dart';

class SymptomManagementScreen extends ConsumerWidget {
  const SymptomManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, RecordPath> recordPaths =
        ref.watch(recordProvider(PageProps(context: context)));
    final Map<Period, List<CheckinItem>> checkin =
        ref.watch(checkinProvider(CheckInProps(context: context)));
    final bool isSmall = getBreakpoint(context).isLessThan(Breakpoint.medium);

    return PageWrap(
      actions: [
        if (!isSmall)
          ...TabOption.values.map((tab) => LargeNavButton(tab: tab)),
        const UserProfileButton(
          selected: true,
        )
      ],
      bottomNav: isSmall ? const SmallLayout() : null,
      child: RefreshWidget(
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
                        context.pushNamed(Routes.ACCOUNT);
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
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  "Categories",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...[
                const Divider(
                  endIndent: 8.0,
                  indent: 8.0,
                ),
                const AddCategoryWidget(),
                Center(
                  child: FilledButton.icon(
                    onPressed: () {},
                    label: const Text("Add Category"),
                  ),
                ),
                ...recordPaths.keys.map((key) {
                  final RecordPath path = recordPaths[key]!;
                  final int symptoms = path.pages.isEmpty
                      ? 0
                      : path.pages
                          .map((page) => page.questionIds.length)
                          .reduce((value, element) => value + element);

                  bool locked = true;
                  return ListTile(
                    title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: true,
                            onChanged: locked ? null : (_) {},
                            thumbIcon: locked
                                ? WidgetStateProperty.all(
                                    const Icon(Icons.lock))
                                : null,
                          ),
                          const SizedBox(
                            width: 4.0,
                          ),
                          Text(key),
                        ]),
                    subtitle: Text("$symptoms symptoms"),
                    trailing: const Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      context.pushNamed(Routes.SYMPTOMTYPE,
                          pathParameters: {'type': key});
                    },
                  );
                }).separated(
                    by: const Divider(
                      endIndent: 8.0,
                      indent: 8.0,
                    ),
                    includeEnds: true),
              ],
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
      ),
    );
  }
}

class AddCategoryWidget extends ConsumerStatefulWidget {
  const AddCategoryWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _AddCategoryWidgetState();
  }
}

class _AddCategoryWidgetState extends ConsumerState<ConsumerStatefulWidget> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
        child: AnimatedSize(
          duration: Durations.medium1,
          child: Form(
            key: formKey,
            child: Opacity(
              opacity: isLoading ? 0.6 : 1.0,
              child: IgnorePointer(
                ignoring: isLoading,
                child: Column(
                  children: [],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
