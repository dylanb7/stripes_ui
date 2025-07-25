import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/AccountManagement/birth_year_selector.dart';
import 'package:stripes_ui/UI/AccountManagement/gender_dropdown.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/form_input.dart';
import 'package:stripes_ui/Util/paddings.dart';

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
    final isSmall = getBreakpoint(context).isLessThan(Breakpoint.medium);

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
              highlightColor: Theme.of(context).colorScheme.onSurface,
              highlightWidth: 1.0,
              highlightOnShrink: true,
              elevated: false,
              header: Padding(
                padding: const EdgeInsetsGeometry.all(AppPadding.tiny),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    AnimatedOpacity(
                      duration: Durations.medium1,
                      opacity: _expandibleListener.expanded ? 0 : 1,
                      child: const Icon(
                        Icons.add,
                      ),
                    ),
                  ],
                ),
              ),
              view: FocusTraversalGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: AppPadding.medium,
                      ),
                      if (isName) ...[
                        TextFormField(
                          controller: _firstName,
                          validator: nameValidator,
                          decoration: formFieldDecoration(
                              hintText: 'First Name', controller: _firstName),
                        ),
                        const SizedBox(
                          height: AppPadding.small,
                        ),
                        TextFormField(
                          controller: _lastName,
                          validator: nameValidator,
                          decoration: formFieldDecoration(
                              hintText: 'Last Name', controller: _lastName),
                        ),
                        const SizedBox(
                          height: AppPadding.small,
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
                                width: AppPadding.small,
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
                        Padding(
                          padding: const EdgeInsetsGeometry.symmetric(
                              horizontal: AppPadding.small),
                          child: TextFormField(
                            validator: (name) {
                              if (name == null || name.isEmpty) {
                                return 'Empty Field';
                              }
                              return null;
                            },
                            controller: _firstName,
                            decoration: formFieldDecoration(
                              hintText: 'Enter Profile Name',
                              controller: _firstName,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(
                        height: AppPadding.large,
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
                height: AppPadding.xxl,
              ),
          ]),
          if (_expandibleListener.expanded)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: FilledButton.icon(
                  onPressed: () {
                    _addUser(isName);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Create New Profile',
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
