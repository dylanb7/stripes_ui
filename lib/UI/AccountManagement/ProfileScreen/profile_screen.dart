import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stripes_backend_helper/stripes_backend_helper.dart';

import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';

import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/entry.dart';

import 'add_profile_widget.dart';
import 'profiles_view.dart';

class PatientScreen extends ConsumerWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = getBreakpoint(context).isLessThan(Breakpoint.medium);
    final double itemWidth = Breakpoint.small.value;
    final StripesConfig config = ref.watch(configProvider);

    final subNotifier = ref.watch(subHolderProvider);
    if (subNotifier.isLoading) {
      return const LoadingWidget();
    }
    final List<SubUser> subUsers = subNotifier.valueOrNull?.subUsers ?? [];
    final SubUser? current = subNotifier.valueOrNull?.selected;
    return PageWrap(
      actions: [
        if (!isSmall)
          ...TabOption.values.map((tab) => LargeNavButton(tab: tab)),
        const UserProfileButton(
          selected: true,
        )
      ],
      bottomNav: isSmall ? const SmallLayout() : null,
      child: RefreshWidget(
        depth: RefreshDepth.subuser,
        scrollable: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(
              height: 20.0,
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      context.goNamed(Routes.ACCOUNT);
                    },
                    icon: const Icon(Icons.keyboard_arrow_left)),
                Text(
                  'Profiles',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.left,
                ),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text("Info"))
              ],
            ),
            const SizedBox(
              height: 6.0,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Your app account, created with your email and password, can be accessed on multiple devices. Share your account credentials with caregivers, such as nurses, school caregivers, and other parents, to allow them to access the account. You can also create profiles for multiple individuals and use the app to track symptoms for each person. To record symptoms, simply switch to the profile of the person you want to track.",
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(
              height: 12.0,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Wrap(children: [
                SizedBox(
                  width: itemWidth,
                  child: const AddUserWidget(),
                ),
                ...subUsers.map<Widget>(
                  (user) => SizedBox(
                    width: itemWidth,
                    child: config.profileType == ProfileType.username
                        ? MinimalProfileView(
                            subUser: user, selected: user.uid == current?.uid)
                        : ProfileView(
                            subUser: user,
                            selected: user.uid == current?.uid,
                          ),
                  ),
                )
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
