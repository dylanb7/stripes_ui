import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/PatientManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/PatientManagement/control_slider.dart';
import 'package:stripes_ui/UI/PatientManagement/gender_dropdown.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
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
                side: BorderSide(color: buttonDarkBackground2, width: 5)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                            const Text(
                              'Edit Patient',
                              style: lightBackgroundHeaderStyle,
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
                                  color: darkIconButton,
                                ))
                          ],
                        ),
                        const SizedBox(
                          height: 6.0,
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'First Name',
                                style: lightBackgroundStyle.copyWith(
                                    color: buttonDarkBackground),
                              ),
                              SizedBox(
                                width: 200,
                                child: TextFormField(
                                  controller: _firstName,
                                  validator: nameValidator,
                                  decoration: formFieldDecoration(
                                      hintText: 'First Name',
                                      controller: _firstName,
                                      clearable: false),
                                ),
                              ),
                            ]),
                        const SizedBox(
                          height: 6.0,
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Last Name',
                                style: lightBackgroundStyle.copyWith(
                                    color: buttonDarkBackground),
                              ),
                              SizedBox(
                                width: 200,
                                child: TextFormField(
                                  controller: _lastName,
                                  validator: nameValidator,
                                  decoration: formFieldDecoration(
                                      hintText: 'First Name',
                                      controller: _lastName,
                                      clearable: false),
                                ),
                              ),
                            ]),
                        const SizedBox(
                          height: 6.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Birth Year",
                              style: lightBackgroundStyle.copyWith(
                                  color: buttonDarkBackground),
                            ),
                            SizedBox(
                              width: 200,
                              child: BirthYearSelector(
                                context: context,
                                controller: _birthYearController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 6.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Gender",
                              style: lightBackgroundStyle.copyWith(
                                  color: buttonDarkBackground),
                            ),
                            SizedBox(
                              width: 200,
                              child: GenderDropdown(
                                context: context,
                                initialValue: widget.subUser.gender,
                                holder: _genderHolder,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Role",
                              style: lightBackgroundStyle.copyWith(
                                  color: buttonDarkBackground),
                            ),
                            SizedBox(
                              width: 200,
                              child: PatientControlSelector(
                                listener: _sliderListener,
                                initialValue: _sliderListener.isControl,
                                context: context,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 6.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            widget.subUser != subNotif.current
                                ? StripesTextButton(
                                    buttonText: 'Delete Patient',
                                    onClicked: () {
                                      _deleteUser(ref);
                                    },
                                    mainTextColor:
                                        lightBackgroundText.withOpacity(0.6),
                                  )
                                : const SizedBox(
                                    width: 8.0,
                                  ),
                            SizedBox(
                                width: 150,
                                child: StripesRoundedButton(
                                  disabled: !canSave,
                                  disabledClick: () {
                                    showSnack('Must make changes before saving',
                                        context);
                                  },
                                  text: 'Save Changes',
                                  onClick: () {
                                    _editUser(ref);
                                  },
                                  light: false,
                                )),
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
        isControl: _sliderListener.isControl,
        id: widget.subUser.uid);
    return !subEquals(newUser, widget.subUser);
  }

  _editUser(WidgetRef ref) {
    _formKey.currentState?.save();
    if (_formKey.currentState?.validate() ?? false) {
      final SubUser newUser = SubUser(
          name: '${_firstName.text} ${_lastName.text}',
          gender: _genderHolder.gender!,
          birthYear: _birthYearController.year,
          isControl: _sliderListener.isControl,
          id: widget.subUser.uid);
      if (!subEquals(newUser, widget.subUser)) {
        ref.read(subProvider)?.updateSubUser(newUser);
      }
      _close(ref);
    }
  }

  _deleteUser(WidgetRef ref) {
    ref.read(subProvider)?.deleteSubUser(widget.subUser);
  }
}

subEquals(SubUser user1, SubUser user2) =>
    user1.uid == user2.uid &&
    user1.birthYear == user2.birthYear &&
    user1.gender == user2.gender &&
    user1.name == user2.name &&
    user1.isControl == user2.isControl;
