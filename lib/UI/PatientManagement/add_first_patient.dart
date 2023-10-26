import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/form_container.dart';
import 'package:stripes_ui/UI/PatientManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/PatientManagement/control_slider.dart';
import 'package:stripes_ui/UI/PatientManagement/gender_dropdown.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/Util/validators.dart';

class CreatePatient extends ConsumerWidget {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final TextEditingController _firstName = TextEditingController(),
      _lastName = TextEditingController();

  final BirthYearController _yearController = BirthYearController();

  final GenderHolder _genderValue = GenderHolder();

  final PatientControlSliderListener _isControlListener =
      PatientControlSliderListener();

  CreatePatient({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormContainer(
      hasClose: false,
      topPortion: Column(
        children: [
          const Spacer(),
          RichText(
              text: TextSpan(
                  text: 'Patient Profile ',
                  style: darkBackgroundScreenHeaderStyle,
                  children: [
                TextSpan(
                    text: '#1',
                    style: darkBackgroundHeaderStyle.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 40))
              ])),
          const Text(
            'Please fill in the information for your first patient',
            textAlign: TextAlign.center,
            style: darkBackgroundStyle,
          ),
          const Spacer(),
        ],
      ),
      form: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: FocusTraversalGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 12.0,
                ),
                TextFormField(
                  validator: nameValidator,
                  controller: _firstName,
                  decoration: formFieldDecoration(
                      hintText: 'First Name', controller: _firstName),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                TextFormField(
                  validator: nameValidator,
                  controller: _lastName,
                  decoration: formFieldDecoration(
                      hintText: 'Last Name', controller: _lastName),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                BirthYearSelector(
                  controller: _yearController,
                  context: context,
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
                          holder: _genderValue,
                        )),
                    const SizedBox(
                      width: 8.0,
                    ),
                    Expanded(
                      flex: 1,
                      child: PatientControlSelector(
                        listener: _isControlListener,
                        context: context,
                      ),
                    ),
                  ],
                )),
                const SizedBox(
                  height: 8.0,
                ),
                FilledButton(
                  child: const Text('Add Patient'),
                  onPressed: () {
                    _submit(context, ref);
                  },
                ),
                const SizedBox(
                  height: 12.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context, WidgetRef ref) async {
    _formKey.currentState?.save();
    if ((_formKey.currentState?.validate() ?? false)) {
      final SubUser user = SubUser(
          name: '${_firstName.text} ${_lastName.text}',
          gender: _genderValue.gender!,
          birthYear: _yearController.year,
          isControl: _isControlListener.isControl);
      final subRepo = ref.read(subProvider);
      if (subRepo == null) {
        showSnack('Unable to add patient', context);
      } else {
        await subRepo.addSubUser(user);
      }
    }
  }
}
