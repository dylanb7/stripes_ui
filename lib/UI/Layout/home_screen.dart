import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/PatientManagement/add_first_patient.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';

import '../../Providers/overlay_provider.dart';
import '../CommonWidgets/user_profile_button.dart';

@immutable
class NavPath {
  final TabOption option;
  const NavPath({required this.option});
}

final tabProvider = StateProvider<TabOption>((_) => TabOption.record);

class Home extends ConsumerWidget {
  final NavPath path;

  const Home({required this.path, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = ref.watch(overlayProvider);
    final AsyncValue<SubState> subNotif = ref.watch(subHolderProvider);
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;

    if (subNotif.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (subNotif.hasError) {}
    final SubState state = subNotif.value!;
    final bool empty = state.subUsers.isEmpty;
    Widget wrap({required Widget child, bool hasUser = false}) {
      return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                scrolledUnderElevation: 1,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Theme.of(context).dividerColor)),
                title: Image.asset(
                  'packages/stripes_ui/assets/images/StripesLogo.png',
                  fit: BoxFit.contain,
                  height: 50,
                ),
                centerTitle: false,
                actions: hasUser
                    ? [
                        if (!isSmall)
                          ...TabOption.values
                              .map((tab) => LargeNavButton(tab: tab)),
                        const UserProfileButton()
                      ]
                    : null,
              ),
              body: child,
              bottomNavigationBar:
                  isSmall && hasUser ? const SmallLayout() : null,
            ),
            if (overlay.widget != null) Scaffold(body: overlay.widget!)
          ],
        ),
      );
    }

    if (empty || state.selected == null || SubUser.isEmpty(state.selected!)) {
      return wrap(child: CreatePatient());
    }
    return wrap(child: const TabContent(), hasUser: true);
  }
}
