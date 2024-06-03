import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/form_container.dart';
import 'package:stripes_ui/UI/PatientManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/PatientManagement/gender_dropdown.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/validators.dart';

class CreatePatient extends ConsumerWidget {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final TextEditingController _firstName = TextEditingController(),
      _lastName = TextEditingController();

  final BirthYearController _yearController = BirthYearController();

  final GenderHolder _genderValue = GenderHolder();

  CreatePatient({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormContainer(
      hasClose: false,
      topPortion: Column(
        children: [
          const Spacer(),
          RichText(
              text: TextSpan(
                  text: 'Profile ',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary),
                  children: [
                TextSpan(
                    text: '#1',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 28))
              ])),
          Text(
            'Please fill in the information for your first profile',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
          const Spacer(),
        ],
      ),
      form: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
              IntrinsicHeight(
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: BirthYearSelector(
                      controller: _yearController,
                      context: context,
                    ),
                  ),
                  const SizedBox(
                    width: 8.0,
                  ),
                  Expanded(
                      flex: 1,
                      child: GenderDropdown(
                        context: context,
                        holder: _genderValue,
                      )),
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
    );
  }

  void _submit(BuildContext context, WidgetRef ref) async {
    _formKey.currentState?.save();
    if ((_formKey.currentState?.validate() ?? false)) {
      final SubUser user = SubUser(
          name: '${_firstName.text} ${_lastName.text}',
          gender: _genderValue.gender!,
          birthYear: _yearController.year,
          isControl: false);
      await ref.read(subProvider).valueOrNull?.addSubUser(user);
    }
  }
}
