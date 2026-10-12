import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Record/record_session_writer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/History/EventView/sig_dates.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/record_layout_shell.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';

import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';

class SubmitScreen extends ConsumerStatefulWidget {
  final String type;

  final SessionGraph questionsListener;
  final List<Question> submitQuestions;

  const SubmitScreen({
    required this.questionsListener,
    required this.type,
    this.submitQuestions = const [],
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SubmitScreenState();
}

class SubmitScreenState extends ConsumerState<SubmitScreen> {
  final DateListener _dateListener = DateListener();

  final TimeListener _timeListener = TimeListener();

  final TextEditingController _descriptionController = TextEditingController();

  bool isLoading = false;

  late final bool isEdit;

  late final Timer _updateSubmitTime;

  @override
  void initState() {
    isEdit = widget.questionsListener.editId != null;
    if (widget.questionsListener.submitTime != null) {
      _dateListener.date = widget.questionsListener.submitTime!.toLocal();
      _timeListener.time = TimeOfDay.fromDateTime(
        widget.questionsListener.submitTime!.toLocal(),
      );
    }
    if (widget.questionsListener.description != null) {
      _descriptionController.text = widget.questionsListener.description!;
    }
    widget.questionsListener.addListener(_state);
    _dateListener.addListener(_setSubmissionTime);
    _timeListener.addListener(_setSubmissionTime);
    _descriptionController.addListener(_updateDesc);
    _updateSubmitTime = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !isEdit && widget.questionsListener.submitTime == null) {
        setState(() {
          final DateTime current = DateTime.now();
          _dateListener.date = current;
          _timeListener.time = TimeOfDay.fromDateTime(current);
        });
      }
    });
    super.initState();
  }

  _setSubmissionTime() {
    _updateSubmitTime.cancel();
    widget.questionsListener.submitTime = _combinedTime();
  }

  _updateDesc() {
    widget.questionsListener.description = _descriptionController.text;
  }

  DateTime _combinedTime() {
    if (isEdit && widget.questionsListener.submitTime != null) {
      return widget.questionsListener.submitTime!;
    }

    final Period? period = ref
        .read(pagesByPath(PagesByPathProps(pathName: widget.type)))
        .value
        ?.path
        ?.period;
    final DateTime date = _dateListener.date;
    final TimeOfDay time = _timeListener.time;
    final currentTime = DateTime.now();
    final DateTime combinedEntry = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      currentTime.second,
      currentTime.millisecond,
    );
    return period?.getValue(combinedEntry) ?? combinedEntry;
  }

  _state() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.questionsListener.removeListener(_state);
    _dateListener.removeListener(_setSubmissionTime);
    _timeListener.removeListener(_setSubmissionTime);
    _descriptionController.removeListener(_updateDesc);
    _updateSubmitTime.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations = QuestionsLocalizations.of(
      context,
    );

    final String localizedType =
        localizations?.value(widget.type) ?? widget.type;

    final StripesConfig config = ref.watch(configProvider);
    final bool betaFlow = config.betaUi.multiSessionFlow;
    final bool themed = config.betaUi.useCategoryTheme;
    final bool colored = config.betaUi.categoryColorsEnabled;
    final CategoryAppearance appearance = CategoryTheme.resolve(widget.type);
    final String fullTitle = isEdit
        ? context.translate.editSubmitHeader(localizedType)
        : context.translate.submitHeader(localizedType);

    List<Widget> buildSubmitTitleWidgets() {
      if (!themed || !fullTitle.contains(localizedType)) {
        return [
          Text(
            fullTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ];
      }

      final parts = fullTitle.split(localizedType);
      final prefix = parts[0];
      final suffix = parts.sublist(1).join(localizedType);

      return [
        if (prefix.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: AppPadding.tiny),
            child: Text(
              prefix.trim(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.medium,
            vertical: 4.0,
          ),
          decoration: BoxDecoration(
            color: colored
                ? appearance.color.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryIcon(appearance: appearance, size: 20),
              const SizedBox(width: AppPadding.tiny),
              Flexible(
                child: Text(
                  localizedType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colored
                        ? appearance.color
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (suffix.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: AppPadding.tiny),
            child: Text(
              suffix.trim(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ];
    }

    final Period? period = ref
        .watch(pagesByPath(PagesByPathProps(pathName: widget.type)))
        .value
        ?.path
        ?.period;

    List<Question> testAdditions = widget.submitQuestions;

    if (isEdit) {
      testAdditions = testAdditions
          .where((q) => widget.questionsListener.fromQuestion(q) != null)
          .toList();
    }

    // Get completion info from parent controller
    final controller = RecordEntryProvider.maybeOf(context);
    final int totalQuestions = controller?.totalQuestions ?? 0;
    final int answeredQuestions = controller?.answeredQuestions ?? 0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: betaFlow ? double.infinity : Breakpoint.tiny.value,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: betaFlow ? 0 : AppPadding.medium,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppPadding.small),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: buildSubmitTitleWidgets(),
              ),
              const SizedBox(height: AppPadding.xl),
              if (period != null)
                Text(
                  period.getRangeString(DateTime.now(), context),
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else if (isEdit && _approximateTimeLabel(context, ref) != null)
                Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${context.translate.dateChangeEntry(_dateListener.date)} · ${_approximateTimeLabel(context, ref)}',
                    ),
                  ),
                )
              else
                _DateTimeCard(
                  dateListener: _dateListener,
                  timeListener: _timeListener,
                  enabled: !isEdit,
                ),
              if (testAdditions.isNotEmpty) ...[
                const SizedBox(height: AppPadding.large),
                RenderQuestions(
                  questions: testAdditions,
                  questionsListener: widget.questionsListener,
                ),
              ],
              if (totalQuestions > 0) ...[
                const SizedBox(height: AppPadding.large),
                _CompletionSummaryCard(
                  answered: answeredQuestions,
                  total: totalQuestions,
                  appearance: colored ? appearance : null,
                ),
              ],
              const SizedBox(height: AppPadding.large),
              LongTextEntry(
                textController: _descriptionController,
                hintText: betaFlow
                    ? context.translate.recordNotes
                    : "$localizedType description",
                labelText: betaFlow ? context.translate.recordNotes : null,
                helperText: betaFlow
                    ? context.translate.optionalResponseDescription
                    : null,
                expandToFill: betaFlow,
              ),
              const SizedBox(height: AppPadding.large),
            ],
          ),
        ),
      ),
    );
  }

  String? _approximateTimeLabel(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesStreamProvider).value ?? const <Entry>[];
    for (final entry in entries) {
      if (entry.id == widget.questionsListener.editId &&
          entry.timeOfDay != null &&
          entry.timeOfDay != TimeOfDayEntry.exact) {
        return RecordTime.fromEntry(entry).label(context);
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Consolidated Date + Time card
// ---------------------------------------------------------------------------

class _DateTimeCard extends StatelessWidget {
  final DateListener dateListener;
  final TimeListener timeListener;
  final bool enabled;

  const _DateTimeCard({
    required this.dateListener,
    required this.timeListener,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: Listenable.merge([dateListener, timeListener]),
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRounding.medium),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Date half
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: enabled
                              ? () => _showDatePicker(context)
                              : null,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(AppRounding.medium),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.medium,
                              vertical: AppPadding.medium,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppPadding.small),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        context.translate.dateChangeTitle,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colors.onSurfaceVariant,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.translate.dateChangeEntry(
                                          dateListener.date,
                                        ),
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          decoration: enabled
                                              ? TextDecoration.underline
                                              : null,
                                          decorationColor: colors.primary
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (enabled)
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 20,
                                    color: colors.onSurfaceVariant,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    // Time half
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: enabled
                              ? () => _showTimePicker(context)
                              : null,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(AppRounding.medium),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.medium,
                              vertical: AppPadding.medium,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppPadding.small),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        context.translate.timeChangeTitle,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colors.onSurfaceVariant,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeListener.time.format(context),
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          decoration: enabled
                                              ? TextDecoration.underline
                                              : null,
                                          decorationColor: colors.primary
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (enabled)
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 20,
                                    color: colors.onSurfaceVariant,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (timeListener.error != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppPadding.medium,
                  top: AppPadding.tiny,
                ),
                child: Text(
                  timeListener.error!,
                  style: TextStyle(color: colors.error),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime now = DateTime.now();
    DateTime? res = await showDatePicker(
      context: context,
      initialDate: dateListener.date,
      firstDate: SigDates.minDate,
      lastDate: now,
    );
    if (res == null) return;
    dateListener.setDate(res);
  }

  Future<void> _showTimePicker(BuildContext context) async {
    TimeOfDay? res = await showTimePicker(
      context: context,
      initialTime: timeListener.time,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (res == null) return;
    timeListener.setError(null);
    timeListener.setTime(res);
  }
}

// ---------------------------------------------------------------------------
// Completion summary card
// ---------------------------------------------------------------------------

class _CompletionSummaryCard extends StatelessWidget {
  final int answered;
  final int total;
  final CategoryAppearance? appearance;

  const _CompletionSummaryCard({
    required this.answered,
    required this.total,
    this.appearance,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool isComplete = answered >= total;
    final Color accentColor = appearance?.color ?? colors.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRounding.medium),
        color: accentColor.withValues(alpha: 0.06),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRounding.medium),
                  bottomLeft: Radius.circular(AppRounding.medium),
                ),
              ),
            ),
            const SizedBox(width: AppPadding.medium),
            // Status icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete
                    ? accentColor.withValues(alpha: 0.15)
                    : colors.surfaceContainerHighest,
              ),
              child: Icon(
                isComplete ? Icons.check_rounded : Icons.pending_outlined,
                size: 18,
                color: isComplete ? accentColor : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppPadding.medium),
            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppPadding.medium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isComplete
                          ? '$answered of $total questions answered'
                          : '$answered of $total questions answered',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isComplete ? accentColor : colors.onSurface,
                      ),
                    ),
                    if (isComplete)
                      Text(
                        'Ready to submit',
                        style: textTheme.bodySmall?.copyWith(
                          color: accentColor.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppPadding.medium),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Description entry (elevated design)
// ---------------------------------------------------------------------------

class LongTextEntry extends ConsumerWidget {
  final TextEditingController textController;
  final String hintText;
  final String? labelText;
  final String? helperText;
  final bool expandToFill;

  const LongTextEntry({
    required this.textController,
    required this.hintText,
    this.labelText,
    this.helperText,
    this.expandToFill = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: expandToFill
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        Text(
          labelText ?? context.translate.submitDescriptionTag,
          style: labelText != null
              ? textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)
              : textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppPadding.tiny),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: expandToFill ? double.infinity : Breakpoint.tiny.value,
          ),
          child: ListenableBuilder(
            listenable: textController,
            builder: (context, _) {
              final hasText = textController.text.isNotEmpty;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openDescriptionEditor(context, ref),
                  borderRadius: BorderRadius.circular(AppRounding.medium),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 72),
                    padding: const EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      border: Border.all(
                        color: hasText
                            ? colors.outlineVariant
                            : colors.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(AppRounding.medium),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            hasText
                                ? textController.text
                                : context
                                      .translate
                                      .submitDescriptionPlaceholder,
                            style: hasText
                                ? textTheme.bodyMedium
                                : textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppPadding.small),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primaryContainer.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          child: Icon(
                            hasText ? Icons.edit : Icons.add,
                            size: 16,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDescriptionEditor(BuildContext context, WidgetRef ref) {
    ref
        .read(sheetControllerProvider)
        .show<String>(
          context: context,
          scrollControlled: true,
          initialChildSize:
              labelText != null &&
                  MediaQuery.textScalerOf(context).scale(14) > 21
              ? 0.9
              : 0.7,
          snapSizes: const [0.7, 0.9],
          avoidKeyboard: true,
          sheetBuilder: (context, scrollController) => _DescriptionEditorSheet(
            initialText: textController.text,
            scrollController: scrollController,
            hintText: hintText,
            labelText: labelText,
          ),
        )
        .then((result) {
          if (result != null) {
            textController.text = result;
          }
        });
  }
}

class _DescriptionEditorSheet extends StatefulWidget {
  final String initialText;
  final String hintText;
  final String? labelText;
  final ScrollController scrollController;

  const _DescriptionEditorSheet({
    required this.initialText,
    required this.scrollController,
    required this.hintText,
    this.labelText,
  });

  @override
  State<_DescriptionEditorSheet> createState() =>
      _DescriptionEditorSheetState();
}

class _DescriptionEditorSheetState extends State<_DescriptionEditorSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    // Auto-focus the text field when the sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    context.pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.pop(_controller.text);
        }
      },
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppPadding.medium,
              AppPadding.small,
              AppPadding.small,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.labelText ?? context.translate.submitDescriptionTag,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    context.translate.doneButton,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Text field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.medium,
                vertical: AppPadding.small,
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: widget.scrollController,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(height: 1.5),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
