import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/symptom_type_management.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

import '../../../Util/Design/paddings.dart';

class SymptomManagementScreen extends ConsumerWidget {
  const SymptomManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecordPath>> asyncRecordPaths =
        ref.watch(questionLayoutProvider);
    return AsyncValueDefaults(
        value: asyncRecordPaths,
        onData: (recordPaths) {
          return Column(
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
                          context.goNamed(RouteName.ACCOUNT);
                        }
                      },
                      icon: const Icon(Icons.keyboard_arrow_left)),
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor),
                    textAlign: TextAlign.left,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      ref.read(sheetControllerProvider).show(
                            context: context,
                            scrollControlled: true,
                            child: (context) {
                              return const SingleChildScrollView(
                                child: AddCategorySheet(),
                              );
                            },
                          );
                    },
                    icon: const Icon(
                      Icons.add,
                    ),
                  ),
                  const SizedBox(
                    width: AppPadding.tiny,
                  ),
                ],
              ),
              const SizedBox(
                height: AppPadding.medium,
              ),
              Divider(
                thickness: 1,
                height: 1,
                endIndent: AppPadding.small,
                indent: AppPadding.small,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              Expanded(
                child: RefreshWidget(
                  depth: RefreshDepth.subuser,
                  scrollable: ListView(
                    children: [
                      const SizedBox(
                        height: AppPadding.small,
                      ),
                      ...recordPaths.map((path) {
                        return CategoryDisplay(recordPath: path);
                      }).separated(
                        by: const Divider(
                          endIndent: AppPadding.medium,
                          indent: AppPadding.medium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /*
            ...checkin.keys.map((items) {
              items.map((item) => {
                item.
              });
              return Container();
            })*/
            ],
          );
        });
  }
}

class CategoryDisplay extends ConsumerWidget {
  final RecordPath recordPath;

  const CategoryDisplay({required this.recordPath, super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final int symptoms = recordPath.pages.fold<int>(
        0, (previousValue, page) => previousValue + page.questionIds.length);
    final RecordPath translated =
        localizations?.translatePath(recordPath) ?? recordPath;
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppPadding.tiny, horizontal: AppPadding.large),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          context.pushNamed(RouteName.SYMPTOMTYPE,
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
                      text: translated.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: translated.enabled
                              ? null
                              : Theme.of(context).disabledColor),
                      children: [
                        if (recordPath.userCreated)
                          TextSpan(
                            text: " · custom category",
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
                  Text(
                    "$symptoms symptom${symptoms == 1 ? "" : "s"}${recordPath.period != null ? " / ${recordPath.period!.name}" : ""}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            IconButton(
                onPressed: () {
                  ref.read(sheetControllerProvider).show(
                        context: context,
                        child: (context) {
                          return CategorySettingsSheet(
                            path: recordPath,
                          );
                        },
                      );
                },
                icon: const Icon(Icons.more_horiz))
          ],
        ),
      ),
    );
  }
}

class AddCategorySheet extends ConsumerStatefulWidget {
  const AddCategorySheet({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return AddCategorySheetState();
  }
}

class AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  final ValueNotifier<AddCategoryFormState> _formState =
      ValueNotifier<AddCategoryFormState>(AddCategoryFormState.idle);
  final TextEditingController category = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Period? recordPeriod;

  final Map<Period, String> frequencyMap = {
    Period.day: "Daily",
    Period.week: "Weekly",
    Period.month: "Monthly",
    Period.year: "Yearly",
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppPadding.large,
          right: AppPadding.large,
          top: AppPadding.large),
      child: Form(
        key: formKey,
        child: Opacity(
          opacity: _formState.value == AddCategoryFormState.loading ? 0.6 : 1.0,
          child: IgnorePointer(
            ignoring: _formState.value == AddCategoryFormState.loading,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Add Category",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(
                  height: AppPadding.small,
                ),
                LabeledField(
                  label: "Category",
                  child: TextFormField(
                    decoration: const InputDecoration(
                        hintText: "name",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                                Radius.circular(AppRounding.tiny)))),
                    controller: category,
                    validator: (value) => value == null || value.isEmpty
                        ? "Must provide a category"
                        : null,
                  ),
                ),
                const SizedBox(
                  height: AppPadding.small,
                ),
                Row(
                  children: [
                    Text(
                      "Frequency",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    DropdownMenuFormField<Period?>(
                      enableSearch: false,
                      enableFilter: false,
                      inputDecorationTheme: InputDecorationThemeData(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppPadding.tiny),
                        ),
                      ),
                      initialSelection: null,
                      onSelected: (value) {
                        setState(() {
                          recordPeriod = value;
                        });
                      },
                      dropdownMenuEntries: [...Period.values, null]
                          .map<DropdownMenuEntry<Period?>>((option) =>
                              DropdownMenuEntry(
                                  value: option,
                                  label: frequencyMap[option] ?? "Event"))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(
                  height: AppPadding.large,
                ),
                Center(
                  child: FilledButton(
                    onPressed: () async {
                      await add();
                    },
                    child: _formState.value == AddCategoryFormState.success
                        ? const Icon(Icons.check)
                        : _formState.value == AddCategoryFormState.loading
                            ? const ButtonLoadingIndicator()
                            : const Text("Add"),
                  ),
                ),
                const SizedBox(
                  height: AppPadding.xxl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> add() async {
    if (_formState.value == AddCategoryFormState.loading) return;

    if (!(formKey.currentState?.validate() ?? false)) return;
    final QuestionRepo? repo = await ref.read(questionsProvider.future);

    if (repo == null) {
      if (mounted) showSnack(context, "Failed to add question");
      return;
    }
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
      context.pop();
      setState(() {
        _formState.value = AddCategoryFormState.idle;
      });
    }
  }
}

class CategorySettingsSheet extends ConsumerStatefulWidget {
  final RecordPath path;

  const CategorySettingsSheet({required this.path, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return CategorySettingsSheetState();
  }
}

class CategorySettingsSheetState extends ConsumerState<CategorySettingsSheet> {
  late final int symptoms;

  bool deleteTried = false, lockTried = false;

  @override
  void initState() {
    symptoms = widget.path.pages.fold<int>(
        0, (previousValue, page) => previousValue + page.questionIds.length);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Map<Period, String> frequencyMap = {
      Period.day: "Daily",
      Period.week: "Weekly",
      Period.month: "Monthly",
      Period.year: "Yearly",
    };
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final AsyncValue<RecordPath?> path = ref.watch(
      questionLayoutProvider.select(
        (value) => value.whenData((path) =>
            path.where((path) => path.id == widget.path.id).firstOrNull),
      ),
    );
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding:
            const EdgeInsetsGeometry.symmetric(horizontal: AppPadding.large),
        child: AsyncValueDefaults(
          value: path,
          onData: (path) {
            if (path == null) return Text("Failed to load ${widget.path.name}");
            final RecordPath translated =
                localizations?.translatePath(path) ?? path;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  height: AppPadding.large,
                ),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          text: translated.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: translated.enabled
                                      ? null
                                      : Theme.of(context).disabledColor),
                          children: [
                            if (translated.userCreated) ...[
                              TextSpan(
                                text: " · custom category",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.75),
                                    ),
                              )
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: AppPadding.tiny,
                    ),
                    IconButton(
                        onPressed: () {
                          context.pop();
                        },
                        icon: const Icon(Icons.keyboard_arrow_down))
                  ],
                ),
                Text(
                  "$symptoms symptom${symptoms == 1 ? "" : "s"}${translated.period != null ? " / ${translated.period!.name}" : ""}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75)),
                ),
                const SizedBox(
                  height: AppPadding.small,
                ),
                /*Row(
                  children: [
                    Text(
                      "Frequency",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (widget.path.userCreated)
                      DropdownMenu<Period?>(
                        enableSearch: false,
                        enableFilter: false,
                        inputDecorationTheme: InputDecorationThemeData(
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppPadding.tiny),
                          ),
                        ),
                        initialSelection: path.period,
                        onSelected: (value) async {
                          if (!await (await ref.read(questionsProvider.future))!
                                  .setPathEnabled(path, !path.enabled) &&
                              context.mounted) {
                            showSnack(context,
                                "Failed to ${!widget.path.enabled ? "enable" : "disable"} ${widget.path.name}");
                          }
                        },
                        dropdownMenuEntries: [...Period.values, null]
                            .map<DropdownMenuEntry<Period?>>((option) =>
                                DropdownMenuEntry(
                                    value: option,
                                    label: frequencyMap[option] ?? "Event"))
                            .toList(),
                      )
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRounding.tiny),
                          border: Border.all(width: 0.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsetsGeometry.symmetric(
                              horizontal: AppPadding.xl,
                              vertical: AppPadding.large),
                          child: Text(frequencyMap[path.period] ?? "Event"),
                        ),
                      ),
                  ],
                ),*/
                const Divider(),
                if (translated.locked && lockTried)
                  Center(
                    child: Text(
                      "This category is currently locked on ${widget.path.enabled ? "enabled" : "disabled"}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(
                  children: [
                    Text(
                      "Enabled",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          lockTried = true;
                        });
                      },
                      child: Switch(
                        value: translated.enabled,
                        onChanged: translated.locked
                            ? null
                            : (_) async {
                                if (!await (await ref
                                            .read(questionsProvider.future))!
                                        .setPathEnabled(path, !path.enabled) &&
                                    context.mounted) {
                                  showSnack(context,
                                      "Failed to ${!translated.enabled ? "enable" : "disable"} ${translated.name}");
                                }
                              },
                        thumbIcon: translated.locked
                            ? WidgetStateProperty.all(const Icon(Icons.lock))
                            : null,
                      ),
                    ),
                  ],
                ),
                if (!translated.userCreated && deleteTried)
                  Center(
                    child: Text(
                      "Cannot delete a predefined category. Disable it to remove it from the record page",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        deleteTried = true;
                      });
                    },
                    child: FilledButton.icon(
                      onPressed: translated.userCreated
                          ? () async {
                              if (!await (await ref
                                          .read(questionsProvider.future))!
                                      .removeRecordPath(path) &&
                                  context.mounted) {
                                showSnack(context,
                                    "Failed to deleted ${widget.path.name}");
                              }
                            }
                          : null,
                      label: const Text("Delete"),
                      icon: const Icon(Icons.delete),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.errorContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum AddCategoryFormState { idle, loading, success }
