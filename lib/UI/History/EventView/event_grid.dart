import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/History/EventView/entry_display.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/home_screen.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class EventGrid extends ConsumerStatefulWidget {
  const EventGrid({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EventGridState();
}

class _EventGridState extends ConsumerState<EventGrid> {
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        _scroll(context)?.addListener(_onScroll);
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;
    final List<Response> available =
        ref.watch(availibleStampsProvider.select((value) => value.filtered));
    if (available.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)!.noEventsText,
              style: darkBackgroundHeaderStyle,
              textAlign: TextAlign.center,
              maxLines: null,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
      sliver: isSmall
          ? SliverList(
              delegate: SliverChildBuilderDelegate(
                  (context, index) => EntryDisplay(event: available[index]),
                  childCount: available.length),
            )
          : SliverMasonryGrid(
              delegate: SliverChildBuilderDelegate(
                  (context, index) => EntryDisplay(event: available[index]),
                  childCount: available.length),
              gridDelegate:
                  const SliverSimpleGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
              ),
            ),
    );
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  ScrollPosition? _scroll(BuildContext context) {
    if (!mounted) return null;
    _scrollPosition = context
        .findAncestorWidgetOfExactType<CustomScrollView>()
        ?.controller
        ?.position;
    return _scrollPosition;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _onScroll() {
    if (_scrollPosition == null || !mounted) return;
    final bool offset = _scrollPosition!.pixels >= 200.0;
    final ScrollDirection scrollDir = _scrollPosition!.userScrollDirection;
    final bool visible = ref.read(actionProvider) != null;
    if (!visible && offset && scrollDir == ScrollDirection.reverse) {
      ref.read(actionProvider.notifier).state = FloatingActionButton(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        tooltip: 'Scroll To Top',
        onPressed: () {
          if ((_scrollPosition?.pixels ?? 0) > 2000) {
            _scrollPosition?.moveTo(0);
          }
          _scrollPosition?.animateTo(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn);
        },
        elevation: 15.0,
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.arrow_upward,
          color: lightIconButton,
        ),
      );
    } else if (scrollDir == ScrollDirection.forward || !offset) {
      ref.read(actionProvider.notifier).state = null;
    }
  }
}
