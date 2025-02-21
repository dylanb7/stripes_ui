import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/AccountManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/AccountManagement/gender_dropdown.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/form_input.dart';

import 'package:stripes_ui/Util/validators.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/entry.dart';

class AddUserWidget extends ConsumerStatefulWidget {
  const AddUserWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddUserWidgetState();
}

class _AddUserWidgetState extends ConsumerState<AddUserWidget> {
  final BirthYearController _yearController = BirthYearController();

  final GenderHolder _genderController = GenderHolder();

  late final ExpandibleController _expandibleListener;

  final GlobalKey<FormState> _formKey = GlobalKey();

  final TextEditingController _firstName = TextEditingController(),
      _lastName = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    _expandibleListener = ExpandibleController(true);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _expandibleListener.addListener(() {
        setState(() {});
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;

    final bool isName =
        ref.watch(configProvider).profileType == ProfileType.name;
    return Opacity(
      opacity: isLoading ? 0.6 : 1,
      child: IgnorePointer(
        ignoring: isLoading,
        child: Stack(children: [
          Column(children: [
            Expandible(
              listener: _expandibleListener,
              highlightColor: Theme.of(context).colorScheme.onPrimary,
              highlightWidth: 1.0,
              highlightOnShrink: true,
              elevated: false,
              header: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _expandibleListener.expanded ? 0 : 1,
                    child: const Icon(
                      Icons.add,
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
                      if (isName) ...[
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
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 1,
                                child: BirthYearSelector(
                                  context: context,
                                  controller: _yearController,
                                ),
                              ),
                              const SizedBox(
                                width: 8.0,
                              ),
                              Expanded(
                                flex: 1,
                                child: GenderDropdown(
                                  context: context,
                                  holder: _genderController,
                                ),
                              ),
                            ],
                          ),
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
                        height: 25.0,
                      )
                    ],
                  ),
                ),
              ),
              hasIndicator: false,
              canExpand: isSmall,
            ),
            if (_expandibleListener.expanded)
              const SizedBox(
                height: 25,
              ),
          ]),
          if (_expandibleListener.expanded)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: SizedBox(
                  width: 120,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      _addUser(isName);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add',
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  _addUser(bool isName) async {
    _formKey.currentState?.save();
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });
      final SubUser toAdd = isName
          ? SubUser(
              name: '${_firstName.text} ${_lastName.text}',
              gender: _genderController.gender!,
              birthYear: _yearController.year,
              isControl: false)
          : SubUser(
              name: _firstName.text,
              gender: "",
              birthYear: 0,
              isControl: false);
      await ref.read(subProvider).valueOrNull?.addSubUser(toAdd);
      setState(() {
        isLoading = false;
      });
      _formKey.currentState?.reset();
    }
  }
}
