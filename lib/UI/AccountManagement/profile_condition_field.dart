import 'package:flutter/material.dart';
import 'package:stripes_ui/Models/profile_condition.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class ProfileConditionField extends StatefulWidget {
  final ProfileCondition? initialValue;
  final ValueChanged<ProfileCondition?> onChanged;
  final bool required;
  final bool enabled;

  const ProfileConditionField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.required = false,
    this.enabled = true,
  });

  @override
  State<ProfileConditionField> createState() => _ProfileConditionFieldState();
}

class _ProfileConditionFieldState extends State<ProfileConditionField> {
  late String? _selection;
  late final TextEditingController _details;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialValue?.selection;
    _details = TextEditingController(text: widget.initialValue?.details ?? '');
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _changed() => widget.onChanged(
    _selection == null
        ? null
        : ProfileCondition(
            _selection!,
            details: _selection == 'Other' ? _details.text.trim() : '',
          ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<String>(
        initialValue: _selection,
        isExpanded: true,
        isDense: false,
        itemHeight: null,
        // Let long selections wrap with larger reading sizes, without the
        // menu rows' extra touch-target padding inside the field itself.
        selectedItemBuilder: (context) => [
          for (final choice in ProfileCondition.choices) Text(choice),
        ],
        decoration: const InputDecoration(
          labelText: 'Condition',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
        items: [
          for (final choice in ProfileCondition.choices)
            DropdownMenuItem(value: choice, child: Text(choice)),
        ],
        onChanged: widget.enabled
            ? (value) {
                setState(() => _selection = value);
                _changed();
              }
            : null,
        validator: (value) => widget.required && value == null
            ? 'Please select a condition'
            : null,
      ),
      if (_selection == 'Other') ...[
        const SizedBox(height: AppPadding.large),
        TextFormField(
          controller: _details,
          enabled: widget.enabled,
          decoration: const InputDecoration(
            labelText: 'Specify condition',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
          ),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _changed(),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Please specify the condition'
              : null,
        ),
      ],
    ],
  );
}
