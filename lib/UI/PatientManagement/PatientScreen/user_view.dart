import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/expandible.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

import 'edit_patient.dart';

class UserView extends ConsumerWidget {
  final SubUser subUser;

  final bool selected;

  const UserView({required this.subUser, required this.selected, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = ref.watch(isSmallProvider);
    return Expandible(
      canExpand: isSmall,
      selected: selected,
      highlightOnShrink: true,
      header: Text(
        subUser.name,
        style: lightBackgroundHeaderStyle,
      ),
      view: Column(
        children: [
          const SizedBox(
            height: 6.0,
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Birth Year:",
                    style: lightBackgroundStyle.copyWith(
                        color: buttonDarkBackground),
                  ),
                  Text(
                    "Gender:",
                    style: lightBackgroundStyle.copyWith(
                        color: buttonDarkBackground),
                  ),
                  Text(
                    "Role:",
                    style: lightBackgroundStyle.copyWith(
                        color: buttonDarkBackground),
                  ),
                ],
              ),
              const SizedBox(
                width: 16.0,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${subUser.birthYear}",
                    style: lightBackgroundStyle,
                  ),
                  Text(
                    subUser.gender,
                    style: lightBackgroundStyle,
                  ),
                  Text(
                    subUser.isControl ? 'Control' : 'Patient',
                    style: lightBackgroundStyle,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(
            height: 6.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              selected
                  ? Text(
                      'Current Patient',
                      style: lightBackgroundStyle.copyWith(
                          color: buttonDarkBackground),
                    )
                  : StripesTextButton(
                      buttonText: 'Select',
                      mainTextColor: lightBackgroundText.withOpacity(0.6),
                      onClicked: () {
                        _changeToCurrent(ref);
                      }),
              IconButton(
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                onPressed: () {
                  _editPatient(ref);
                },
                icon: const Icon(Icons.edit, color: darkIconButton),
              )
            ],
          ),
          const SizedBox(
            height: 6.0,
          ),
        ],
      ),
    );
  }

  _changeToCurrent(WidgetRef ref) {
    ref.read(subHolderProvider.notifier).changeCurrent(subUser);
  }

  _editPatient(WidgetRef ref) {
    ref.read(overlayProvider.notifier).state =
        OverlayQuery(widget: EditUserWidget(subUser: subUser));
  }
}
