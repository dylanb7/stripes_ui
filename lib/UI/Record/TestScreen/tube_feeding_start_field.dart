import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';

/// Records when the blue feeding started, including a previous calendar day.
class TubeFeedingStartField extends StatelessWidget {
  final DateTime? start;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  const TubeFeedingStartField({
    required this.start,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final localStart = start?.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tube feeding',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppPadding.small),
        const Text(
          'Record when feeding with blue dye started. '
          'You can continue tracking while feeding is ongoing.',
        ),
        const SizedBox(height: AppPadding.medium),
        const Text('Feeding started at:'),
        TextButton.icon(
          key: const ValueKey('tube-feeding-start-picker'),
          onPressed: enabled ? () => _pickStart(context) : null,
          icon: const Icon(Icons.edit_calendar),
          label: Text(
            localStart == null
                ? 'Select date and time'
                : '${localizations.formatMediumDate(localStart)} · '
                      '${TimeOfDay.fromDateTime(localStart).format(context)}',
          ),
        ),
        const SizedBox(height: AppPadding.small),
        Center(
          child: OutlinedButton.icon(
            onPressed: enabled ? () => onChanged(DateTime.now()) : null,
            icon: const Icon(Icons.schedule),
            label: const Text('Use current time'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickStart(BuildContext context) async {
    final now = DateTime.now();
    final initial = start?.toLocal() ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Feeding start date',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Feeding start time',
    );
    if (time == null || !context.mounted) return;
    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (selected.isAfter(DateTime.now())) {
      showSnack(context, 'Feeding start cannot be in the future.');
      return;
    }
    onChanged(selected);
  }
}
