import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class BirthYearController {
  DateTime _birthYear = DateTime(2005);

  late bool _wasSet;

  bool _hasChanged = false;

  BirthYearController({int? initialYear}) {
    _wasSet = initialYear != null;
    _birthYear = _wasSet ? DateTime(initialYear!) : DateTime(2005);
  }

  changeYear(DateTime year) {
    _hasChanged = true;
    _birthYear = year;
  }

  DateTime get birthYear => _birthYear;

  int get year => _birthYear.year;
}

class BirthYearSelector extends FormField<String> {
  BirthYearSelector(
      {required BirthYearController controller,
      required BuildContext context,
      super.key})
      : super(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            initialValue: controller._wasSet ? '${controller.year}' : null,
            validator: (String? value) {
              return value != null && value.isNotEmpty ? null : 'Not Set';
            },
            builder: (state) {
              return IntrinsicHeight(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text(
                              'Select Birth Year',
                              style: lightBackgroundHeaderStyle,
                            ),
                            content: Theme(
                              data: ThemeData.from(
                                      colorScheme: const ColorScheme.dark()
                                          .copyWith(
                                              primary: buttonDarkBackground,
                                              secondary: buttonDarkBackground2,
                                              onSurface: Colors.black))
                                  .copyWith(
                                      splashFactory: NoSplash.splashFactory),
                              child: SizedBox(
                                width: 300,
                                height: 300,
                                child: YearPicker(
                                  currentDate: controller.birthYear,
                                  firstDate: DateTime(1940),
                                  lastDate: DateTime.now(),
                                  selectedDate: controller.birthYear,
                                  onChanged: (val) {
                                    controller.changeYear(val);
                                    state.didChange('${controller.year}');
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    IgnorePointer(
                        ignoring: true,
                        child: TextField(
                          controller: TextEditingController(
                              text: controller._hasChanged || controller._wasSet
                                  ? '${controller.year}'
                                  : null),
                          decoration: formFieldDecoration(
                              hintText: 'Birth Year',
                              errorText: state.errorText,
                              controller: TextEditingController(),
                              clearable: false),
                        )),
                  ],
                ),
              ).showCursorOnHover;
            });
}

/*class BirthYearWidget extends StatefulWidget {
  final BirthYearController controller;

  const BirthYearWidget({required this.controller, Key? key}) : super(key: key);

  @override
  _BirthYearWidgetState createState() => _BirthYearWidgetState();
}

class _BirthYearWidgetState extends State<BirthYearWidget> {
  TextEditingController year = TextEditingController();
  @override
  Widget build(BuildContext context) {
    if (widget.controller._wasSet) {
      year.text = _text;
    }
    return InkWell(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      enableFeedback: true,
      mouseCursor: SystemMouseCursors.click,
      child: TextFormField(
        enabled: false,
        autofillHints: const [AutofillHints.birthdayYear],
        controller: year,
        validator: (value) => (value ?? '').isEmpty ? 'Empty Field' : null,
        decoration: formFieldDecoration(
            hintText: 'Birth Year', controller: year, clearable: false),
      ),
      onTap: () {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text(
                  'Select Birth Year',
                  style: lightBackgroundHeaderStyle,
                ),
                content: Theme(
                  data: ThemeData.from(
                          colorScheme: const ColorScheme.dark().copyWith(
                              primary: buttonDarkBackground,
                              secondary: buttonDarkBackground2,
                              onSurface: Colors.black))
                      .copyWith(splashFactory: NoSplash.splashFactory),
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: YearPicker(
                      firstDate: DateTime(1940),
                      lastDate: DateTime.now(),
                      selectedDate: widget.controller.birthYear,
                      onChanged: (val) {
                        setState(() {
                          widget.controller.changeYear(val);
                          year.text = _text;
                        });
                        Navigator.pop(context);
                      },
                      currentDate: widget.controller.birthYear,
                    ),
                  ),
                )));
      },
    );
  }

  String get _text => 'Birth Year: ${widget.controller.year}';
}*/
