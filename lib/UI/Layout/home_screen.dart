import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/Layout/fabs.dart';
import 'package:stripes_ui/UI/PatientManagement/add_first_patient.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';

import '../../Providers/overlay_provider.dart';
import '../CommonWidgets/user_profile_button.dart';

@immutable
class NavPath {
  final TabOption option;
  const NavPath({required this.option});
}

class Home extends ConsumerWidget {
  final TabOption selected;

  const Home({required this.selected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SubState> subNotif = ref.watch(subHolderProvider);
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;

    if (subNotif.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final SubState state = subNotif.value!;
    final bool empty = state.subUsers.isEmpty;
    if (empty || state.selected == null || SubUser.isEmpty(state.selected!)) {
      return PageWrap(child: CreatePatient());
    }
    return PageWrap(
      actions: [
        if (!isSmall)
          ...TabOption.values.map((tab) => LargeNavButton(
                tab: tab,
                selected: selected,
              )),
        const SizedBox(
          width: 8.0,
        ),
        const UserProfileButton()
      ],
      bottomNav: isSmall
          ? SmallLayout(
              selected: selected,
            )
          : null,
      child: TabContent(
        selected: selected,
      ),
    );
  }
}

class PageWrap extends ConsumerStatefulWidget {
  final Widget child;

  final List<Widget>? actions;

  final Widget? bottomNav;

  final Widget? leading;

  final FabState? fabState;

  const PageWrap(
      {required this.child,
      this.actions,
      this.bottomNav,
      this.leading,
      this.fabState,
      super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _PageWrapState();
  }
}

class _PageWrapState extends ConsumerState<PageWrap> {
  PersistentBottomSheetController? sheetController;

  _PageWrapState();

  @override
  Widget build(BuildContext context) {
    final CurrentOverlay overlay = ref.watch(overlayProvider);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: widget.leading,
              scrolledUnderElevation: 0,
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).dividerColor)),
              titleSpacing: widget.leading != null ? 5.0 : null,
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Builder(builder: (context) {
                  return GestureDetector(
                    onTap: () {
                      _toggleBottomSheet(context);
                    },
                    child: Image.asset(
                      'packages/stripes_ui/assets/images/StripesLogo.png',
                      fit: BoxFit.contain,
                      height: 35,
                    ).showCursorOnHover,
                  );
                }),
              ),
              centerTitle: false,
              actions: widget.actions != null
                  ? [...widget.actions!, const SizedBox(width: 8)]
                  : null,
            ),
            body: widget.child,
            floatingActionButton: widget.fabState?.fab,
            floatingActionButtonLocation: widget.fabState?.location,
            floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
            bottomNavigationBar: widget.bottomNav,
          ),
          if (overlay.widget != null)
            Material(color: Colors.transparent, child: overlay.widget!)
        ],
      ),
    );
  }

  _toggleBottomSheet(BuildContext context) {
    if (sheetController != null) {
      sheetController!.close();
      sheetController = null;
    } else {
      sheetController = Scaffold.of(context).showBottomSheet((context) {
        return const StripesInfoSheet();
      });
    }
  }
}

class StripesInfoSheet extends StatelessWidget {
  const StripesInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('BottomSheet'),
            ElevatedButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
