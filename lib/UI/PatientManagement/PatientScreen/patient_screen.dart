import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';

import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

import 'add_user_widget.dart';
import 'user_view.dart';

class PatientScreen extends ConsumerWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double itemWidth = SMALL_LAYOUT / 1.5;
    final bool isSmall = ref.watch(isSmallProvider);
    final OverlayQuery overlay = ref.watch(overlayProvider);
    final SubNotifier subNotifier = ref.watch(subHolderProvider);
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [backgroundStrong, backgroundLight])),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isSmall
                          ? const Flexible(
                              child: Text(
                              'Select a patient to view their profile.',
                              maxLines: 2,
                              style: darkBackgroundHeaderStyle,
                            ))
                          : Container(),
                      IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          iconSize: 40,
                          icon: const Icon(
                            Icons.close,
                            color: darkIconButton,
                          ))
                    ],
                  )),
              const SizedBox(
                height: 12.0,
              ),
              const Text(
                'Patient Profiles',
                style: darkBackgroundScreenHeaderStyle,
              ),
              const SizedBox(
                height: 12.0,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    children: subNotifier.users
                        .map<Widget>(
                          (user) => SizedBox(
                            width: itemWidth,
                            child: UserView(
                              subUser: user,
                              selected: user.uid == subNotifier.current.uid,
                            ),
                          ),
                        )
                        .toList()
                      ..add(
                        const SizedBox(
                          width: itemWidth,
                          child: AddUserWidget(),
                        ),
                      ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (overlay.widget != null) overlay.widget!
    ]);
  }
}
