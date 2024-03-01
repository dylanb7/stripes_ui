import 'package:flutter/material.dart';

String? empty(String? val) {
  return val == null ? 'Not set' : null;
}

class GenderHolder {
  String? gender;
}

class GenderDropdown extends FormField<String> {
  GenderDropdown(
      {required GenderHolder holder,
      required BuildContext context,
      String? initialValue,
      AutovalidateMode autovalidate = AutovalidateMode.onUserInteraction,
      Key? key})
      : super(
            key: key,
            validator: empty,
            autovalidateMode: autovalidate,
            initialValue: initialValue,
            builder: (FormFieldState<String> state) {
              final List<String> values = ["Male", "Female", "Other"];
              return DropdownMenu<String>(
                enableSearch: false,
                expandedInsets: const EdgeInsets.all(0),
                onSelected: (value) {
                  holder.gender = value;
                  state.didChange(value);
                },
                hintText: "Gender",
                initialSelection: state.value,
                dropdownMenuEntries: values
                    .map((e) => DropdownMenuEntry(value: e, label: e))
                    .toList(),
                errorText: state.errorText,
              );
            });
}
