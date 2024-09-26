import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';

import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';

import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import 'add_user_widget.dart';
import 'user_view.dart';

class PatientScreen extends ConsumerWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;
    const double itemWidth = SMALL_LAYOUT / 1.5;

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 20.0,
            ),
            Row(
              children: [
                Text(
                  'Profiles',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.left,
                ),
                const Spacer(),
                FilledButton(
                    onPressed: () {
                      ref.read(authProvider).logOut();
                    },
                    child: Text(AppLocalizations.of(context)!.logOutButton))
              ],
            ),
            const SizedBox(
              height: 12.0,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  children: subUsers
                      .map<Widget>(
                        (user) => SizedBox(
                          width: itemWidth,
                          child: UserView(
                            subUser: user,
                            selected: user.uid == current?.uid,
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
    );
  }
}
