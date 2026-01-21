import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/AccountManagement/gender_dropdown.dart';
import 'package:stripes_ui/Util/Helpers/form_input.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Helpers/validators.dart';
import 'package:stripes_ui/config.dart';

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

  bool _isLoading = false;

  @override
  void initState() {
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StripesConfig config = ref.watch(configProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;

    // Block navigation - user must create a profile first
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppPadding.large),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Compact header with icon and text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppPadding.medium),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add_outlined,
                            size: 28,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppPadding.medium),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome!',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                            ),
                            Text(
                              "Let's create your first profile",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.large),

                    // Form Card - now first
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppPadding.medium),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (config.profileType == ProfileType.name) ...[
                                TextFormField(
                                  validator: nameValidator,
                                  controller: _firstName,
                                  autofocus: true,
                                  decoration: formFieldDecoration(
                                    hintText: 'First Name',
                                    controller: _firstName,
                                  ),
                                ),
                                const SizedBox(height: AppPadding.small),
                                TextFormField(
                                  validator: nameValidator,
                                  controller: _lastName,
                                  decoration: formFieldDecoration(
                                    hintText: 'Last Name',
                                    controller: _lastName,
                                  ),
                                ),
                                const SizedBox(height: AppPadding.small),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: BirthYearSelector(
                                          controller: _yearController,
                                          context: context,
                                        ),
                                      ),
                                      const SizedBox(width: AppPadding.small),
                                      Expanded(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                          },
                                          child: GenderDropdown(
                                            context: context,
                                            holder: _genderValue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                TextFormField(
                                  validator: (name) {
                                    if (name == null || name.isEmpty) {
                                      return 'Please enter a username';
                                    }
                                    return null;
                                  },
                                  controller: _firstName,
                                  autofocus: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: formFieldDecoration(
                                    hintText: 'Username',
                                    controller: _firstName,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppPadding.medium),
                              FilledButton.icon(
                                onPressed: _isLoading ? null : _submit,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check),
                                label: Text(_isLoading
                                    ? 'Creating...'
                                    : 'Create Profile'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      setState(() => _isLoading = true);
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
