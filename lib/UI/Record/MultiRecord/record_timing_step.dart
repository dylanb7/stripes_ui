import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/Record/multi_record_draft.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class _TimingChoice extends StatelessWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  const _TimingChoice({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: label,
      selected: selected,
      onSelected: onSelected,
      selectedColor: colors.primary,
      checkmarkColor: colors.onPrimary,
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.onSurface,
      ),
    );
  }
}

class RecordTimingStep extends ConsumerWidget {
  final MultiRecordDraft draft;
  const RecordTimingStep({required this.draft, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final isToday = DateUtils.isSameDay(draft.date, today);
    final isYesterday = DateUtils.isSameDay(draft.date, yesterday);
    final themed = ref.watch(configProvider).betaUi.useCategoryTheme;
    final localizations = QuestionsLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selected = draft.selected;
    final singleCategory = selected.length == 1 ? selected.single : null;

    Future<void> chooseDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: draft.date,
        firstDate: DateTime(1900),
        lastDate: today,
      );
      if (picked != null) draft.setDate(picked);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.dateChangeTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TimingChoice(
              key: const ValueKey('record-today'),
              label: Text(strings.recordToday),
              selected: isToday,
              onSelected: (_) => draft.setDate(today),
            ),
            _TimingChoice(
              key: const ValueKey('record-yesterday'),
              label: Text(strings.recordYesterday),
              selected: isYesterday,
              onSelected: (_) => draft.setDate(yesterday),
            ),
            _TimingChoice(
              key: const ValueKey('record-earlier'),
              label: Text(strings.recordEarlier),
              selected: !isToday && !isYesterday,
              onSelected: (_) => chooseDate(),
            ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: chooseDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(DateFormat.yMMMMEEEEd(locale).format(draft.date)),
          ),
        ),
        const SizedBox(height: 16),
        if (selected.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TimingChoice(
                key: const ValueKey('record-shared-time'),
                label: Text(strings.recordSameTime),
                selected: !draft.separateTimes,
                onSelected: (_) => draft.setSeparateTimes(false),
              ),
              _TimingChoice(
                key: const ValueKey('record-separate-times'),
                label: Text(strings.recordSeparateTimes),
                selected: draft.separateTimes,
                onSelected: (_) => draft.setSeparateTimes(true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            draft.separateTimes
                ? strings.recordSeparateTimeHelp
                : strings.recordSharedTimeHelp,
          ),
          const SizedBox(height: 20),
        ],
        if (singleCategory != null)
          RecordTimeCard(
            key: ValueKey('record-time-${singleCategory.type}'),
            value: draft.timeFor(singleCategory.type),
            date: draft.date,
            requiresExact: singleCategory.requiresExactTime,
            onChanged: (value) => draft.setTime(
              value,
              type: draft.separateTimes ? singleCategory.type : null,
            ),
            heading: _CategoryLabel(
              type: singleCategory.type,
              title:
                  localizations?.value(singleCategory.type) ??
                  singleCategory.type,
              themed: themed,
            ),
          )
        else if (!draft.separateTimes)
          RecordTimeCard(
            value: draft.sharedTime,
            date: draft.date,
            requiresExact: draft.selected.any(
              (category) => category.requiresExactTime,
            ),
            showSeparateTimeHint: true,
            onChanged: (value) => draft.setTime(value),
            heading: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final category in draft.selected)
                  _CategoryLabel(
                    type: category.type,
                    title: localizations?.value(category.type) ?? category.type,
                    themed: themed,
                  ),
              ],
            ),
          )
        else
          for (final category in draft.selected)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RecordTimeCard(
                key: ValueKey('record-time-${category.type}'),
                value: draft.timeFor(category.type),
                date: draft.date,
                requiresExact: category.requiresExactTime,
                onChanged: (value) => draft.setTime(value, type: category.type),
                heading: _CategoryLabel(
                  type: category.type,
                  title: localizations?.value(category.type) ?? category.type,
                  themed: themed,
                ),
              ),
            ),
      ],
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  final String type;
  final String title;
  final bool themed;
  const _CategoryLabel({
    required this.type,
    required this.title,
    required this.themed,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (themed) ...[
        CategoryIcon(appearance: CategoryTheme.resolve(type), size: 24),
        const SizedBox(width: 8),
      ],
      Flexible(
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
    ],
  );
}

class RecordTimeCard extends StatelessWidget {
  final RecordTime value;
  final DateTime date;
  final bool requiresExact;
  final bool showSeparateTimeHint;
  final ValueChanged<RecordTime> onChanged;
  final Widget heading;
  const RecordTimeCard({
    required this.value,
    required this.date,
    required this.onChanged,
    required this.heading,
    this.requiresExact = false,
    this.showSeparateTimeHint = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final valid = value.isValidFor(
      date,
      DateTime.now(),
      requiresExact: requiresExact,
    );
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final precision in RecordTimePrecision.values)
                  _TimingChoice(
                    key: ValueKey('precision-${precision.name}'),
                    label: Text(switch (precision) {
                      RecordTimePrecision.exact => strings.recordExactTime,
                      RecordTimePrecision.dayPart => strings.recordTimeOfDay,
                      RecordTimePrecision.unknown => strings.recordNotSure,
                    }),
                    selected: value.precision == precision,
                    onSelected:
                        requiresExact && precision != RecordTimePrecision.exact
                        ? null
                        : (_) =>
                              onChanged(value.copyWith(precision: precision)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (value.precision == RecordTimePrecision.exact)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  key: const ValueKey('record-exact-time-picker'),
                  onPressed: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: value.exactTime,
                    );
                    if (selected != null) {
                      onChanged(value.copyWith(exactTime: selected));
                    }
                  },
                  icon: const Icon(Icons.schedule),
                  label: Text(value.exactTime.format(context)),
                ),
              )
            else if (value.precision == RecordTimePrecision.dayPart)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final period in RecordDayPart.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        selected: value.dayPart == period,
                        inMutuallyExclusiveGroup: true,
                        child: OutlinedButton(
                          key: ValueKey('period-${period.name}'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                            backgroundColor: value.dayPart == period
                                ? colors.primaryContainer
                                : null,
                            foregroundColor: value.dayPart == period
                                ? colors.onPrimaryContainer
                                : colors.onSurface,
                          ),
                          onPressed: () =>
                              onChanged(value.copyWith(dayPart: period)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(period.label(strings)),
                                    Text(
                                      period.range(context),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                value.dayPart == period
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else
              Text(strings.recordUnknownTimeHelp),
            if (requiresExact) ...[
              const SizedBox(height: 12),
              Text(
                showSeparateTimeHint
                    ? strings.recordStudyExactTime
                    : strings.recordStudyExactTimeOnly,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (!valid) ...[
              const SizedBox(height: 12),
              Text(
                strings.recordInvalidTime,
                style: TextStyle(color: colors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
