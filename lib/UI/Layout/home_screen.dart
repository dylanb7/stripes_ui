import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/scroll_assisted_list.dart';
import 'package:stripes_ui/UI/CommonWidgets/stripes_header.dart';
import 'package:stripes_ui/UI/Layout/fabs.dart';
import 'package:stripes_ui/UI/AccountManagement/add_first_profile.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Providers/overlay_provider.dart';

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

    if (subNotif.isLoading) {
      return const LoadingWidget();
    }

    final SubState state = subNotif.value!;
    final bool empty = state.subUsers.isEmpty;
    if (empty || state.selected == null || SubUser.isEmpty(state.selected!)) {
      return const CreatePatient();
    }
    return TabContent(
      selected: selected,
    );
  }
}

final navBarHeaderKey = GlobalKey<StripesHeaderState>();

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
                titleSpacing: widget.leading != null ? AppPadding.tiny : null,
                title: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppPadding.tiny),
                  child: SizedBox(
                    height: 35.0,
                    child: GestureDetector(
                      onTap: () {
                        _toggleBottomSheet(context);
                      },
                      child: StripesHeader(
                        key: navBarHeaderKey,
                      ),
                    ),
                  ),
                ),
                centerTitle: false,
                actions: widget.actions != null
                    ? [
                        ...widget.actions!,
                        const SizedBox(width: AppPadding.small)
                      ]
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
            topLeft: Radius.circular(AppRounding.large),
            topRight: Radius.circular(AppRounding.large),
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
        context.translate.aboutStripes,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      Text(context.translate.aboutLineOne),
      Text(context.translate.aboutLineTwo),
      Text(context.translate.aboutLineThree),
      InkWell(
        onTap: () => launchUrl(Uri.parse('https://www.bluepoop.info')),
        child: const Text(
          'bluepoop.info',
          style: TextStyle(decoration: TextDecoration.underline),
        ),
      ),
      Text(
        context.translate.aboutQuestionsTitle,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      LabeledList(
          title: Text(
            context.translate.aboutCategoriesTitle,
          ),
          strings: [
            context.translate.aboutDataCollection,
            context.translate.aboutDataSecurity,
            context.translate.aboutStudyQuestions,
            context.translate.aboutStudyResults,
            context.translate.aboutWithdraw,
            context.translate.aboutETC
          ],
          highlight: false),
    ];
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: AppPadding.large,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
            child: Row(
              children: [
                SizedBox(
                  width: Theme.of(context).iconTheme.size ?? 24.0,
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppPadding.small),
                    child: SizedBox(
                      height: 35.0,
                      child: StripesHeader(
                        hasEntry: false,
                        alignment: Alignment.center,
                      ),
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
            height: AppPadding.small,
          ),
          Expanded(
            child: ScrollAssistedList(
                builder: (context, properties) => ListView.builder(
                      controller: properties.scrollController,
                      key: properties.scrollStateKey,
                      itemCount: infoItems.length,
                      itemBuilder: (BuildContext context, int index) => Padding(
                          padding: const EdgeInsets.only(
                            left: AppPadding.large,
                            right: AppPadding.large,
                            bottom: AppPadding.small,
                          ),
                          child: infoItems[index]),
                    ),
                scrollController: scroll),
          ),
        ]);
  }
}
