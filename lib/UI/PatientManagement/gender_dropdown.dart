import 'package:flutter/material.dart';
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
              final List<String> values = ["Male", "Female", "Non-binary"];
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 51,
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 15),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: state.errorText == null
                              ? Border.all(color: Colors.grey)
                              : Border.all(
                                  color: Theme.of(context).colorScheme.error),
                          borderRadius: BorderRadius.circular(5)),
                      child: DropdownButton<String>(
                        onChanged: (value) {
                          holder.gender = value;
                          state.didChange(value);
                        },
                        value: state.value,
                        underline: Container(),
                        hint: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Gender',
                            textAlign: TextAlign.left,
                            style: lightBackgroundStyle.copyWith(
                                color: Colors.black.withOpacity(0.6)),
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_downward,
                        ),
                        isExpanded: true,
                        items: values
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      e,
                                      style: lightBackgroundStyle,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ))
                            .toList(),
                        selectedItemBuilder: (BuildContext context) => values
                            .map((e) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    e,
                                    style: lightBackgroundStyle,
                                    textAlign: TextAlign.left,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                          padding: const EdgeInsets.only(left: 14.0, top: 6.0),
                          child: Text(
                            state.errorText!,
                            textAlign: TextAlign.left,
                            style: errorStyleTitle,
                          )),
                  ]);
            });
}
