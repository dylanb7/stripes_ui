import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/form_container.dart';
import 'package:stripes_ui/UI/PatientManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/PatientManagement/gender_dropdown.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/validators.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/entry.dart';

class CreatePatient extends ConsumerStatefulWidget {
  const CreatePatient({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _CreatePatientState();
  }
}

class _CreatePatientState extends ConsumerState<CreatePatient> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName, _lastName;

  final BirthYearController _yearController = BirthYearController();

  final GenderHolder _genderValue = GenderHolder();

  @override
  void initState() {
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final StripesConfig config = ref.watch(configProvider);

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
            children: config.profileType == ProfileType.name
                ? [
                    const SizedBox(
                      height: 12.0,
                    ),
                    TextFormField(
                      validator: nameValidator,
                      controller: _firstName,
                      decoration: formFieldDecoration(
                        hintText: 'First Name',
                        controller: _firstName,
                      ),
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    TextFormField(
                      validator: nameValidator,
                      controller: _lastName,
                      decoration: formFieldDecoration(
                        hintText: 'Last Name',
                        controller: _lastName,
                      ),
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
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            child: GenderDropdown(
                              context: context,
                              holder: _genderValue,
                            ),
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(
                      height: 8.0,
                    ),
                    FilledButton(
                      child: const Text('Add Profile'),
                      onPressed: () {
                        _submit();
                      },
                    ),
                    const SizedBox(
                      height: 12.0,
                    ),
                  ]
                : [
                    const SizedBox(
                      height: 12.0,
                    ),
                    TextFormField(
                      validator: (name) {
                        if (name == null || name.isEmpty) return 'Empty Field';
                        return null;
                      },
                      controller: _firstName,
                      decoration: formFieldDecoration(
                        hintText: 'Username',
                        controller: _firstName,
                      ),
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    FilledButton(
                      child: const Text('Add Profile'),
                      onPressed: () {
                        _submit();
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

  void _submit() async {
    final bool isName =
        ref.read(configProvider).profileType == ProfileType.name;
    _formKey.currentState?.save();
    if ((_formKey.currentState?.validate() ?? false)) {
      final SubUser user = isName
          ? SubUser(
              name: '${_firstName.text} ${_lastName.text}',
              gender: _genderValue.gender!,
              birthYear: _yearController.year,
              isControl: false)
          : SubUser(
              name: _firstName.text,
              gender: "",
              birthYear: 0,
              isControl: false);
      await ref.read(subProvider).valueOrNull?.addSubUser(user);
    }
  }
}
