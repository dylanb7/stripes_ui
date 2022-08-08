import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

String? empty(String? val) {
  return val == null ? 'Not set' : null;
}

class PatientControlSliderListener {
  bool isControl = false;
}

class PatientControlSelector extends FormField<String> {
  PatientControlSelector(
      {required PatientControlSliderListener listener,
      required BuildContext context,
      bool? initialValue,
      AutovalidateMode autovalidate = AutovalidateMode.onUserInteraction,
      Key? key})
      : super(
            key: key,
            validator: empty,
            autovalidateMode: autovalidate,
            onSaved: (value) {
              listener.isControl = value == 'Control';
            },
            initialValue: initialValue != null
                ? initialValue
                    ? 'Control'
                    : 'Patient'
                : null,
            builder: (FormFieldState<String> state) {
              final List<String> values = ["Patient", "Control"];
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
                              : Border.all(color: error),
                          borderRadius: BorderRadius.circular(5)),
                      child: DropdownButton<String>(
                        onChanged: (value) {
                          listener.isControl = value == 'Control';
                          state.didChange(value);
                        },
                        value: state.value,
                        underline: Container(),
                        hint: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Role',
                            textAlign: TextAlign.left,
                            style: lightBackgroundStyle.copyWith(
                                color: Colors.black.withOpacity(0.6)),
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_downward,
                          color: buttonLightBackground,
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
