import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/baseline_gate.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/scroll_assisted_list.dart';
import 'package:stripes_ui/UI/CommonWidgets/stripes_header.dart';
import 'package:stripes_ui/UI/AccountManagement/add_first_profile.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stripes_ui/UI/CommonWidgets/sync_indicator.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';

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

  final bool floating;

  const PageWrap(
      {required this.child,
      this.actions,
      this.bottomNav,
      this.leading,
      this.floating = false,
      super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _PageWrapState();
  }
}

class _PageWrapState extends ConsumerState<PageWrap> {
  _PageWrapState();

  bool _hideNavBar = false;

  @override
  void didUpdateWidget(covariant PageWrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) {
      if (_hideNavBar) {
        setState(() => _hideNavBar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldHide = widget.floating && _hideNavBar;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = kToolbarHeight + topPadding;

    return BaselineGate(
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(headerHeight),
              child: AnimatedContainer(
                duration: Durations.medium1,
                height: shouldHide ? 0 : headerHeight,
                child: ClipRect(
                  child: AppBar(
                    automaticallyImplyLeading: false,
                    leading: widget.leading,
                    scrolledUnderElevation: 0,
                    titleSpacing:
                        widget.leading != null ? AppPadding.tiny : null,
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
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    centerTitle: false,
                    actions: widget.actions != null
                        ? [
                            ...widget.actions!,
                            const SizedBox(width: AppPadding.small)
                          ]
                        : null,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(1.0),
                      child: Container(
                        height: 1.0,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (!widget.floating) return true;
                if (notification.depth > 0) return true;
                if (notification is UserScrollNotification) {
                  if (notification.direction == ScrollDirection.reverse) {
                    if (!_hideNavBar) {
                      setState(() {
                        _hideNavBar = true;
                      });
                    }
                  }
                  if (notification.direction == ScrollDirection.forward) {
                    if (_hideNavBar) {
                      setState(() {
                        _hideNavBar = false;
                      });
                    }
                  }
                }
                return true;
              },
              child: RepaintBoundary(child: widget.child),
            ),
            bottomNavigationBar: AnimatedContainer(
              duration: Durations.medium1,
              height: shouldHide || widget.bottomNav == null ? 0 : 70,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: widget.bottomNav,
              ),
            ),
          ),
        ),
      ),
    );
  }

  _toggleBottomSheet(BuildContext context) {
    ref.read(sheetControllerProvider).show(
          context: context,
          scrollControlled: true,
          initialChildSize: 0.95,
          maxChildSize: 1.0,
          sheetBuilder: (context, controller) => StripesInfoSheet(
            scrollController: controller,
          ),
        );
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
