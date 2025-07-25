import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/paddings.dart';

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
      super.key})
      : super(
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
                      height: 50,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppPadding.tiny,
                          horizontal: AppPadding.large),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: state.errorText == null
                              ? Border.all(color: Colors.grey)
                              : Border.all(
                                  color: Theme.of(context).colorScheme.error),
                          borderRadius:
                              BorderRadius.circular(AppRounding.tiny)),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Colors.black.withValues(alpha: 0.6)),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
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
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.left,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                          padding: const EdgeInsets.only(
                              left: AppPadding.medium, top: AppPadding.tiny),
                          child: Text(
                            state.errorText!,
                            textAlign: TextAlign.left,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context).colorScheme.error),
                          )),
                  ]);
            });
}
