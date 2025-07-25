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

import '../../../Util/paddings.dart';

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: AppPadding.large,
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
                      height: AppPadding.tiny,
                    ),
                    const Divider(
                      endIndent: AppPadding.small,
                      indent: AppPadding.small,
                    ),
                    const AddCategoryWidget(),
                    ...recordPaths.map((path) {
                      return CategoryDisplay(recordPath: path);
                    }).separated(
                        by: const Divider(
                          endIndent: AppPadding.small,
                          indent: AppPadding.small,
                        ),
                        includeEnds: true),

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
    final int symptoms = recordPath.pages.fold<int>(
        0, (previousValue, page) => previousValue + page.questionIds.length);
    return Padding(
      padding: const EdgeInsets.only(
          top: AppPadding.tiny,
          left: AppPadding.medium,
          right: AppPadding.medium),
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
                  Expanded(
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
                    width: AppPadding.tiny,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(
              height: AppPadding.tiny,
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

enum AddCategoryFormState { idle, adding, loading, success }

class _AddCategoryWidgetState extends ConsumerState<ConsumerStatefulWidget> {
  final _formState =
      ValueNotifier<AddCategoryFormState>(AddCategoryFormState.idle);
  final TextEditingController category = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Period? recordPeriod;
  static const double buttonHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
        child: AnimatedSize(
          duration: Durations.medium1,
          child: Form(
            key: formKey,
            child: Opacity(
              opacity:
                  _formState.value == AddCategoryFormState.loading ? 0.6 : 1.0,
              child: IgnorePointer(
                ignoring: _formState.value == AddCategoryFormState.loading,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_formState.value == AddCategoryFormState.adding) ...[
                      TextButton.icon(
                        onPressed: () {
                          _formState.value = AddCategoryFormState.idle;
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
                        height: AppPadding.large,
                      ),
                    ],
                    FilledButton(
                      onPressed: () async {
                        await add();
                      },
                      child: _formState.value == AddCategoryFormState.success
                          ? const Icon(Icons.check)
                          : _formState.value == AddCategoryFormState.loading
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
    if (_formState.value == AddCategoryFormState.loading) return;
    if (_formState.value != AddCategoryFormState.adding) {
      setState(() {
        _formState.value = AddCategoryFormState.adding;
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
        _formState.value = AddCategoryFormState.success;
      });
      await Future.delayed(Durations.long4);
      recordPeriod = null;
      formKey.currentState?.reset();
    } else if (mounted) {
      showSnack(context, "Failed to add question");
    }
    if (mounted) {
      _formState.value = AddCategoryFormState.idle;
    }
  }
}
