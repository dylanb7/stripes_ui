import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/PatientManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/PatientManagement/control_slider.dart';
import 'package:stripes_ui/UI/PatientManagement/gender_dropdown.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/Util/validators.dart';

class AddUserWidget extends ConsumerStatefulWidget {
  const AddUserWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddUserWidgetState();
}

class _AddUserWidgetState extends ConsumerState<AddUserWidget> {
  final BirthYearController _yearController = BirthYearController();

  final GenderHolder _genderController = GenderHolder();

  late final ExpandibleListener _expandibleListener;

  final GlobalKey<FormState> _formKey = GlobalKey();

  final TextEditingController _firstName = TextEditingController(),
      _lastName = TextEditingController();

  final PatientControlSliderListener _sliderListener =
      PatientControlSliderListener();

  @override
  void initState() {
    _expandibleListener = ExpandibleListener();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _expandibleListener.expanded.addListener(() {
        setState(() {});
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = ref.watch(isSmallProvider);
    return Stack(children: [
      Column(children: [
        Expandible(
          listener: _expandibleListener,
          header: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Patient',
                style: lightBackgroundHeaderStyle,
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _expandibleListener.expanded.value ? 0 : 1,
                child: const Icon(
                  Icons.add,
                  color: darkIconButton,
                ),
              ),
            ],
          ),
          view: FocusTraversalGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    height: 12.0,
                  ),
                  TextFormField(
                    controller: _firstName,
                    validator: nameValidator,
                    decoration: formFieldDecoration(
                        hintText: 'First Name', controller: _firstName),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  TextFormField(
                    controller: _lastName,
                    validator: nameValidator,
                    decoration: formFieldDecoration(
                        hintText: 'Last Name', controller: _lastName),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  BirthYearSelector(
                    context: context,
                    controller: _yearController,
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 1,
                          child: GenderDropdown(
                            context: context,
                            holder: _genderController,
                          ),
                        ),
                        const SizedBox(
                          width: 8.0,
                        ),
                        Expanded(
                          flex: 1,
                          child: PatientControlSelector(
                            listener: _sliderListener,
                            context: context,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 25.0,
                  )
                ],
              ),
            ),
          ),
          hasIndicator: false,
          canExpand: isSmall,
        ),
        const SizedBox(
          height: 25,
        ),
      ]),
      if (_expandibleListener.expanded.value)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 50, height: 50),
            child: ElevatedButton(
              onPressed: () {
                _addUser();
              },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith(
                    (states) => states.contains(MaterialState.hovered) ||
                            states.contains(MaterialState.pressed)
                        ? darkIconButton.withOpacity(0.9)
                        : darkIconButton,
                  ),
                  padding: MaterialStateProperty.all(const EdgeInsets.all(5.0)),
                  shape: MaterialStateProperty.all(const CircleBorder())),
              child: const Text(
                'Add',
                style: darkBackgroundStyle,
              ),
            ),
          ),
        ),
    ]);
  }

  _addUser() {
    _formKey.currentState?.save();
    if (_formKey.currentState?.validate() ?? false) {
      final SubUser toAdd = SubUser(
          name: '${_firstName.text} ${_lastName.text}',
          gender: _genderController.gender!,
          birthYear: _yearController.year,
          isControl: _sliderListener.isControl);
      ref.read(subProvider)?.addSubUser(toAdd);
      _formKey.currentState?.reset();
    }
  }
}
