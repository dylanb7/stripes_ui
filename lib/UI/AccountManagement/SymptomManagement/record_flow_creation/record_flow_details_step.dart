import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_ui/UI/AccountManagement/SymptomManagement/record_flow_creation/record_flow_creation_presentation.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/extensions.dart';

class RecordFlowDetailsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final Period? period;
  final VoidCallback onNameChanged;
  final ValueChanged<Period?> onPeriodChanged;

  const RecordFlowDetailsStep({
    required this.formKey,
    required this.nameController,
    required this.period,
    required this.onNameChanged,
    required this.onPeriodChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.translate.newQuestionSetDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppPadding.large),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.translate.questionSetName,
                hintText: context.translate.questionSetNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.translate.questionSetNameRequired
                  : null,
              onChanged: (_) => onNameChanged(),
            ),
            const SizedBox(height: AppPadding.large),
            Text(
              context.translate.recordTiming,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppPadding.tiny),
            Text(
              context.translate.recordTimingHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppPadding.small),
            Wrap(
              spacing: AppPadding.small,
              runSpacing: AppPadding.tiny,
              children:
                  <Period?>[
                        null,
                        Period.day,
                        Period.week,
                        Period.month,
                        Period.year,
                      ]
                      .map(
                        (option) => ChoiceChip(
                          label: Text(recordFlowTimingLabel(context, option)),
                          selected: period == option,
                          onSelected: (_) => onPeriodChanged(option),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: AppPadding.tiny),
            Text(
              period == null
                  ? context.translate.eventBasedDescription
                  : context.translate.scheduledDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
