import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/text_styles.dart';

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
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 0),
                      decoration: BoxDecoration(
                          border: state.errorText == null
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary)
                              : Border.all(
                                  color: Theme.of(context).colorScheme.error),
                          borderRadius: BorderRadius.circular(5)),
                      child: DropdownMenu<String>(
                        onSelected: (value) {
                          holder.gender = value;
                          state.didChange(value);
                        },
                        initialSelection: state.value,
                        trailingIcon: const Icon(
                          Icons.arrow_downward,
                        ),
                        dropdownMenuEntries: values
                            .map((e) => DropdownMenuEntry(value: e, label: e))
                            .toList(),
                        errorText: state.errorText,
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                          padding: const EdgeInsets.only(left: 14.0, top: 6.0),
                          child: Text(
                            state.errorText!,
                            textAlign: TextAlign.left,
                            style: lightBackgroundStyle.copyWith(
                                fontSize: 14.0,
                                color: Theme.of(context).colorScheme.error),
                          )),
                  ]);
            });
}
