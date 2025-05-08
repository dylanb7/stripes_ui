import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/symptom_type_management.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';

class SymptomManagementScreen extends ConsumerWidget {
  const SymptomManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecordPath>> asyncRecordPaths =
        ref.watch(questionLayoutProvider);

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
        scrollable: AsyncValueDefaults(
            value: asyncRecordPaths,
            onData: (recordPaths) {
              return SingleChildScrollView(
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
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.goNamed(Routes.ACCOUNT);
                              }
                            },
                            icon: const Icon(Icons.keyboard_arrow_left)),
                        Text(
                          'Categories',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
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
                    ...[
                      const Divider(
                        endIndent: 8.0,
                        indent: 8.0,
                      ),
                      const AddCategoryWidget(),
                      ...recordPaths.map((path) {
                        return CategoryDisplay(recordPath: path);
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
              );
            }),
      ),
    );
  }
}

class CategoryDisplay extends ConsumerWidget {
  final RecordPath recordPath;

  const CategoryDisplay({required this.recordPath, super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int symptoms = recordPath.pages.isEmpty
        ? 0
        : recordPath.pages
            .map((page) => page.questionIds.length)
            .reduce((value, element) => value + element);
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 16.0, right: 16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                context.pushNamed(Routes.SYMPTOMTYPE,
                    pathParameters: {'type': recordPath.name});
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: recordPath.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            children: [
                              if (recordPath.userCreated)
                                TextSpan(
                                  text: " · custom category",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .disabledColor
                                              .darken()),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          "$symptoms symptom${symptoms == 1 ? "" : "s"}${recordPath.period != null ? " · ${recordPath.period!.name}" : ""}",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 4.0,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Switch(
                  value: recordPath.enabled,
                  onChanged: recordPath.locked
                      ? null
                      : (_) async {
                          if (!await (await ref.read(questionsProvider.future))
                                  .setPathEnabled(
                                      recordPath, !recordPath.enabled) &&
                              context.mounted) {
                            showSnack(context,
                                "Failed to ${!recordPath.enabled ? "enable" : "disable"} ${recordPath.name}");
                          }
                        },
                  thumbIcon: recordPath.locked
                      ? WidgetStateProperty.all(const Icon(Icons.lock))
                      : null,
                ),
                IconButton(
                    onPressed: recordPath.userCreated
                        ? () async {
                            if (!await (await ref
                                        .read(questionsProvider.future))
                                    .removeRecordPath(recordPath) &&
                                context.mounted) {
                              showSnack(context,
                                  "Failed to deleted ${recordPath.name}");
                            }
                          }
                        : null,
                    icon: const Icon(Icons.delete))
              ],
            ),
          ]),
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
  bool isLoading = false, submitSuccess = false;
  bool isAdding = false;
  final TextEditingController category = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Period? recordPeriod;
  static const double buttonHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAdding) ...[
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            isAdding = false;
                          });
                        },
                        label: const Text("Close"),
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      LabeledField(
                        label: "category",
                        child: TextFormField(
                          controller: category,
                          validator: (value) => value == null || value.isEmpty
                              ? "Must provide a category"
                              : null,
                        ),
                      ),
                      /*
                      const SizedBox(
                        height: 8.0,
                      ),
                      LabeledField(
                        label: "type",
                        child: SelectField<Period?>(
                          onOptionSelected: (option) {
                            setState(() {
                              recordPeriod = option.value;
                            });
                          },
                          menuDecoration: MenuDecoration(
                            animationDuration: Durations.short4,
                            height: min(
                                buttonHeight * (Period.values.length + 1),
                                screenHeight / 2),
                            buttonStyle: TextButton.styleFrom(
                              fixedSize:
                                  const Size(double.infinity, buttonHeight),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.all(16),
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                          initialOption: Option<Period?>(
                            label: "event",
                            value: null,
                          ),
                          options: Period.values
                              .map<Option<Period?>>((option) =>
                                  Option(label: option.name, value: option))
                              .toList()
                            ..add(Option<Period?>(
                              label: "Event",
                              value: null,
                            )),
                        ),
                      ),*/
                      const SizedBox(
                        height: 16.0,
                      ),
                    ],
                    FilledButton(
                      onPressed: () async {
                        await add();
                      },
                      child: submitSuccess
                          ? const Icon(Icons.check)
                          : isLoading
                              ? const ButtonLoadingIndicator()
                              : const Text("Add Category"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> add() async {
    if (isLoading) return;
    if (!isAdding) {
      setState(() {
        isAdding = true;
      });
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;
    final QuestionRepo repo = await ref.read(questionsProvider.future);
    final bool added = await repo.addRecordPath(
      RecordPath(
          pages: const [],
          period: recordPeriod,
          userCreated: true,
          name: category.text),
    );
    if (added && mounted) {
      setState(() {
        category.clear();
        submitSuccess = true;
      });
      await Future.delayed(Durations.long4);
      recordPeriod = null;
      formKey.currentState?.reset();
    } else if (mounted) {
      showSnack(context, "Failed to add question");
    }
    if (mounted) {
      setState(() {
        submitSuccess = false;
        isLoading = false;
        isAdding = false;
      });
    }
  }
}
