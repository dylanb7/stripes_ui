import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/scroll_assisted_list.dart';
import 'package:stripes_ui/UI/Layout/fabs.dart';
import 'package:stripes_ui/UI/AccountManagement/add_first_profile.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final bool isSmall = MediaQuery.of(context).size.width < 1400;

    if (subNotif.isLoading) {
      return const LoadingWidget();
    }

    final SubState state = subNotif.value!;
    final bool empty = state.subUsers.isEmpty;
    if (empty || state.selected == null || SubUser.isEmpty(state.selected!)) {
      return const PageWrap(child: CreatePatient());
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
  _PageWrapState();

  @override
  Widget build(BuildContext context) {
    final CurrentOverlay overlay = ref.watch(overlayProvider);

    return SafeArea(
      child: GestureDetector(
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
              floatingActionButtonAnimator:
                  FloatingActionButtonAnimator.scaling,
              bottomNavigationBar: widget.bottomNav,
            ),
            if (overlay.widget != null)
              Material(color: Colors.transparent, child: overlay.widget!)
          ],
        ),
      ),
    );
  }

  _toggleBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
              initialChildSize: 1.0,
              minChildSize: 1.0,
              builder: (context, controller) {
                return StripesInfoSheet(
                  scrollController: controller,
                );
              });
        });
  }
}

class StripesInfoSheet extends StatelessWidget {
  final ScrollController? scrollController;

  final Function? onClose;

  const StripesInfoSheet({this.onClose, this.scrollController, super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scroll = scrollController ?? ScrollController();
    final List<Widget> infoItems = [
      Text(
        AppLocalizations.of(context)!.aboutStripes,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      Text(AppLocalizations.of(context)!.aboutLineOne),
      Text(AppLocalizations.of(context)!.aboutLineTwo),
      Text(AppLocalizations.of(context)!.aboutLineThree),
      InkWell(
        onTap: () => launchUrl(Uri.parse('https://www.bluepoop.info')),
        child: const Text(
          'bluepoop.info',
          style: TextStyle(decoration: TextDecoration.underline),
        ),
      ),
      Text(
        AppLocalizations.of(context)!.aboutQuestionsTitle,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      LabeledList(
          title: Text(
            AppLocalizations.of(context)!.aboutCategoriesTitle,
          ),
          strings: [
            AppLocalizations.of(context)!.aboutDataCollection,
            AppLocalizations.of(context)!.aboutDataSecurity,
            AppLocalizations.of(context)!.aboutStudyQuestions,
            AppLocalizations.of(context)!.aboutStudyResults,
            AppLocalizations.of(context)!.aboutWithdraw,
            AppLocalizations.of(context)!.aboutETC
          ],
          highlight: false),
    ];
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: 15.0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              children: [
                SizedBox(
                  width: Theme.of(context).iconTheme.size ?? 24.0,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      AppLocalizations.of(context)!.stripesName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton.filled(
                    onPressed: () {
                      if (onClose != null) {
                        onClose!();
                      }
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close))
              ],
            ),
          ),
          const SizedBox(
            height: 8.0,
          ),
          Expanded(
              child: ScrollAssistedList(
                  builder: (context, properties) => ListView.builder(
                        controller: properties.scrollController,
                        key: properties.scrollStateKey,
                        itemCount: infoItems.length,
                        itemBuilder: (BuildContext context, int index) =>
                            Padding(
                                padding: const EdgeInsets.only(
                                  left: 15.0,
                                  right: 15.0,
                                  bottom: 6.0,
                                ),
                                child: infoItems[index]),
                      ),
                  scrollController: scroll)),
        ]);
  }
}
