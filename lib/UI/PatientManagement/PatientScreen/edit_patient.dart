import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/PatientManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/PatientManagement/control_slider.dart';
import 'package:stripes_ui/UI/PatientManagement/gender_dropdown.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/form_input.dart';

import 'package:stripes_ui/Util/validators.dart';

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
    List<String> names = widget.subUser.name.split(' ');
    _firstName = TextEditingController(text: names[0]);
    _lastName = TextEditingController(text: names[1]);
    _birthYearController =
        BirthYearController(initialYear: widget.subUser.birthYear);
    _sliderListener.isControl = widget.subUser.isControl;
    _genderHolder.gender = widget.subUser.gender;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final subNotif = ref.watch(subHolderProvider);
    return OverlayBackdrop(
      child: SizedBox(
        width: SMALL_LAYOUT / 1.5,
        child: IntrinsicHeight(
          child: Card(
            elevation: 12,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
                side: BorderSide(width: 5)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                              height: 6.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Edit Patient',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                IconButton(
                                    onPressed: () {
                                      _close(ref);
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
                              height: 6.0,
                            ),
                            TextFormField(
                              controller: _firstName,
                              validator: nameValidator,
                              decoration: formFieldDecoration(
                                  hintText: 'First Name',
                                  controller: _firstName,
                                  clearable: false),
                            ),
                            const SizedBox(
                              height: 6.0,
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
                              height: 6.0,
                            ),
                            BirthYearSelector(
                              context: context,
                              controller: _birthYearController,
                            ),
                            const SizedBox(
                              height: 6.0,
                            ),
                            GenderDropdown(
                              context: context,
                              initialValue: widget.subUser.gender,
                              holder: _genderHolder,
                            ),
                            const SizedBox(
                              height: 6.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                widget.subUser != subNotif.valueOrNull?.selected
                                    ? TextButton(
                                        child: const Text('Delete Patient'),
                                        onPressed: () {
                                          _deleteUser(ref);
                                        },
                                      )
                                    : const SizedBox(
                                        width: 8.0,
                                      ),
                                SizedBox(
                                  width: 150,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!canSave) {
                                        showSnack(
                                          context,
                                          'Must make changes before saving',
                                        );
                                      }
                                    },
                                    child: FilledButton.tonal(
                                      onPressed: !canSave
                                          ? null
                                          : () {
                                              _editUser(ref);
                                            },
                                      child: const Text('Save Changes'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 12.0,
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
    );
  }

  _close(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state = closedQuery;
  }

  bool _editsMade() {
    if (_genderHolder.gender == null) return false;
    final SubUser newUser = SubUser(
        name: '${_firstName.text} ${_lastName.text}',
        gender: _genderHolder.gender!,
        birthYear: _birthYearController.year,
        isControl: false,
        id: widget.subUser.uid);
    return !subEquals(newUser, widget.subUser);
  }

  _editUser(WidgetRef ref) async {
    _formKey.currentState?.save();
    setState(() {
      isLoading = true;
    });
    if (_formKey.currentState?.validate() ?? false) {
      final SubUser newUser = SubUser(
          name: '${_firstName.text} ${_lastName.text}',
          gender: _genderHolder.gender!,
          birthYear: _birthYearController.year,
          isControl: false,
          id: widget.subUser.uid);
      if (!subEquals(newUser, widget.subUser)) {
        await ref.read(subProvider).valueOrNull?.updateSubUser(newUser);
      }
      setState(() {
        isLoading = false;
      });
      _close(ref);
    }
  }

  _deleteUser(WidgetRef ref) {
    ref.read(subProvider).valueOrNull?.deleteSubUser(widget.subUser);
  }
}

subEquals(SubUser user1, SubUser user2) =>
    user1.uid == user2.uid &&
    user1.birthYear == user2.birthYear &&
    user1.gender == user2.gender &&
    user1.name == user2.name &&
    user1.isControl == user2.isControl;
