import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/base_providers.dart';

import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/AccountManagement/control_slider.dart';
import 'package:stripes_ui/UI/AccountManagement/gender_dropdown.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/Helpers/form_input.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

import 'package:stripes_ui/Util/Helpers/validators.dart';
import 'package:stripes_ui/config.dart';

class EditUserWidget extends ConsumerStatefulWidget {
  final SubUser subUser;

  const EditUserWidget({required this.subUser, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EditUserWidgetState();
}

class _EditUserWidgetState extends ConsumerState<EditUserWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  late final TextEditingController _firstName, _lastName;
  late final BirthYearController _birthYearController;
  final GenderHolder _genderHolder = GenderHolder();
  final PatientControlSliderListener _sliderListener =
      PatientControlSliderListener();
  bool canSave = false;
  bool isLoading = false;

  @override
  void initState() {
    final bool isName =
        ref.read(configProvider).profileType == ProfileType.name;
    if (isName) {
      List<String> names = widget.subUser.name.split(' ');
      _firstName = TextEditingController(text: names[0]);
      _lastName = TextEditingController(text: names[1]);
      _birthYearController =
          BirthYearController(initialYear: widget.subUser.birthYear);
      _sliderListener.isControl = widget.subUser.isControl;
      _genderHolder.gender = widget.subUser.gender;
    } else {
      _firstName = TextEditingController(text: widget.subUser.name);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isName =
        ref.watch(configProvider).profileType == ProfileType.name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
          child: IntrinsicHeight(
            child: Card(
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppRounding.medium)),
                  side: BorderSide(width: 1.0)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppPadding.large),
                child: Opacity(
                  opacity: isLoading ? 0.6 : 1,
                  child: IgnorePointer(
                    ignoring: isLoading,
                    child: FocusTraversalGroup(
                      child: Form(
                        onChanged: () {
                          setState(() {
                            canSave = _editsMade();
                          });
                        },
                        key: _formKey,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(
                                height: AppPadding.small,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Edit Profile',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).primaryColor),
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        _close(context);
                                      },
                                      highlightColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      icon: const Icon(
                                        Icons.close,
                                        size: 35,
                                      ))
                                ],
                              ),
                              const SizedBox(
                                height: AppPadding.medium,
                              ),
                              if (isName) ...[
                                TextFormField(
                                  controller: _firstName,
                                  validator: nameValidator,
                                  decoration: formFieldDecoration(
                                      hintText: 'First Name',
                                      controller: _firstName,
                                      clearable: false),
                                ),
                                const SizedBox(
                                  height: AppPadding.tiny,
                                ),
                                TextFormField(
                                  controller: _lastName,
                                  validator: nameValidator,
                                  decoration: formFieldDecoration(
                                      hintText: 'Last Name',
                                      controller: _lastName,
                                      clearable: false),
                                ),
                                const SizedBox(
                                  height: AppPadding.tiny,
                                ),
                                BirthYearSelector(
                                  context: context,
                                  controller: _birthYearController,
                                ),
                                const SizedBox(
                                  height: AppPadding.tiny,
                                ),
                                GenderDropdown(
                                  context: context,
                                  initialValue: widget.subUser.gender,
                                  holder: _genderHolder,
                                ),
                              ] else ...[
                                TextFormField(
                                  validator: (name) {
                                    if (name == null || name.isEmpty) {
                                      return 'Empty Field';
                                    }
                                    return null;
                                  },
                                  controller: _firstName,
                                  decoration: formFieldDecoration(
                                    hintText: 'Username',
                                    controller: _firstName,
                                  ),
                                ),
                              ],
                              const SizedBox(
                                height: AppPadding.small,
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (!canSave) {
                                    showSnack(
                                      context,
                                      'Must make changes before saving',
                                    );
                                  }
                                },
                                child: FilledButton(
                                  onPressed: !canSave
                                      ? null
                                      : () {
                                          _editUser(ref, context);
                                        },
                                  child: const Text('Save Changes'),
                                ),
                              ),
                              const SizedBox(
                                height: AppPadding.medium,
                              ),
                            ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _close(BuildContext context) {
    Navigator.of(context).pop();
  }

  bool _editsMade() {
    final bool isName =
        ref.watch(configProvider).profileType == ProfileType.name;
    if (!isName) return widget.subUser.name != _firstName.text;
    if (_genderHolder.gender == null) return false;
    final SubUser newUser = SubUser(
        name: '${_firstName.text} ${_lastName.text}',
        gender: _genderHolder.gender!,
        birthYear: _birthYearController.year,
        isControl: false,
        id: widget.subUser.uid);
    return !subEquals(newUser, widget.subUser);
  }

  _editUser(WidgetRef ref, BuildContext context) async {
    final bool isName =
        ref.watch(configProvider).profileType == ProfileType.name;
    _formKey.currentState?.save();
    setState(() {
      isLoading = true;
    });
    if (_formKey.currentState?.validate() ?? false) {
      final SubUser newUser = isName
          ? SubUser(
              name: '${_firstName.text} ${_lastName.text}',
              gender: _genderHolder.gender!,
              birthYear: _birthYearController.year,
              isControl: false,
              id: widget.subUser.uid)
          : SubUser(
              name: _firstName.text,
              gender: "",
              birthYear: 0,
              isControl: false,
              id: widget.subUser.uid);

      await ref.read(subProvider).valueOrNull?.updateSubUser(newUser);

      setState(() {
        isLoading = false;
      });
      _close(context);
    }
  }
}

subEquals(SubUser user1, SubUser user2) =>
    user1.uid == user2.uid &&
    user1.birthYear == user2.birthYear &&
    user1.gender == user2.gender &&
    user1.name == user2.name &&
    user1.isControl == user2.isControl;
