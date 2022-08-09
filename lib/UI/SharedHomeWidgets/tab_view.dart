import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/History/history_screen.dart';
import 'package:stripes_ui/UI/History/location_bar.dart';
import 'package:stripes_ui/UI/PatientManagement/patient_changer.dart';
import 'package:stripes_ui/UI/Record/record_screen.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';

enum TabOption {
  record('Record'),
  history('History');

  const TabOption(this.value);
  final String value;
}

final GlobalKey scrollkey = GlobalKey();

class StripesTabView extends ConsumerWidget {
  final TabOption selected;

  const StripesTabView({required this.selected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    HistoryLocation loc = ref.watch(historyLocationProvider);
    final ScrollController scrollController = ScrollController();
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundStrong, backgroundLight])),
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            ref.watch(isSmallProvider.notifier).state =
                constraints.biggest.width < SMALL_LAYOUT;
          });
          final bool isSmall = ref.read(isSmallProvider);
          Widget scroll = CustomScrollView(
            key: scrollkey,
            controller: scrollController,
            slivers: [
              if (!isSmall) LargeLayout(selected: selected),
              if (selected == TabOption.record) ...const [
                SliverPadding(padding: EdgeInsets.only(top: 20.0)),
                Header(),
                Options(),
              ] else ...[
                const SliverPadding(padding: EdgeInsets.only(top: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const PatientChanger(
                            isRecords: false,
                          ),
                          isSmall
                              ? const UserProileButton()
                              : const SizedBox(
                                  width: 35,
                                )
                        ]),
                  ),
                ),
                const LocationBar(),
                ...SliversConfig(loc).slivers,
                const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
              ]
            ],
          );
          return isSmall
              ? SmallLayout(
                  selected: selected,
                  child: scroll,
                )
              : scroll;
        },
      ),
    );
  }

  handleTap(BuildContext context, TabOption tapped) {
    if (tapped == selected) return;
    if (tapped == TabOption.record) {
      context.go(Routes.HOME);
    } else if (tapped == TabOption.history) {
      context.go(Routes.HISTORY);
    }
  }
}

class SmallLayout extends StatelessWidget {
  final TabOption selected;

  final Widget child;

  const SmallLayout({required this.child, required this.selected, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: child),
      BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: darkBackgroundText,
        selectedLabelStyle:
            lightBackgroundStyle.copyWith(color: backgroundLight),
        currentIndex: TabOption.values.indexOf(selected),
        onTap: (index) {
          context
              .findAncestorWidgetOfExactType<StripesTabView>()!
              .handleTap(context, TabOption.values[index]);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.add,
                color: darkIconButton,
              ),
              label: 'Record'),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.grading,
                color: darkIconButton,
              ),
              label: 'History'),
        ],
      )
    ]);
  }
}

class LargeLayout extends StatelessWidget {
  final TabOption selected;

  const LargeLayout({required this.selected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget getButton(TextStyle style, TabOption option) => TextButton(
        onPressed: () {
          context
              .findAncestorWidgetOfExactType<StripesTabView>()!
              .handleTap(context, option);
        },
        child: Text(
          option.value,
          style: selected == option
              ? darkBackgroundHeaderStyle.copyWith(
                  color: lightIconButton, fontWeight: FontWeight.bold)
              : darkBackgroundHeaderStyle,
        ));

    final bool isRecord = selected == TabOption.record;
    Widget recordButton = isRecord
        ? _decorationWrap(
            child: getButton(
                darkBackgroundHeaderStyle.copyWith(
                    fontSize: 28, color: buttonLightBackground),
                TabOption.record))
        : getButton(
            darkBackgroundHeaderStyle.copyWith(color: darkBackgroundText),
            TabOption.record);
    Widget historyButton = !isRecord
        ? _decorationWrap(
            child: getButton(
                darkBackgroundHeaderStyle.copyWith(
                    fontSize: 28, color: buttonLightBackground),
                TabOption.history))
        : getButton(
            darkBackgroundHeaderStyle.copyWith(color: darkBackgroundText),
            TabOption.history);
    return SliverAppBar(
      snap: true,
      floating: true,
      expandedHeight: 70,
      collapsedHeight: 70,
      backgroundColor: buttonLightBackground2.withOpacity(0.7),
      shadowColor: Colors.black,
      centerTitle: true,
      flexibleSpace: Center(
        child: SizedBox(
          height: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                width: 6.0,
              ),
              _decorationWrap(
                child: Image.asset(
                  'packages/stripes_ui/assets/images/StripesLogo.png',
                ),
              ),
              const Spacer(),
              recordButton,
              const SizedBox(
                width: 12.0,
              ),
              historyButton,
              const SizedBox(
                width: 25.0,
              ),
              const UserProileButton(),
              const SizedBox(
                width: 12.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _decorationWrap({required Widget child}) => DecoratedBox(
        decoration: BoxDecoration(
          color: darkBackgroundText,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
            child: child),
      );
}
