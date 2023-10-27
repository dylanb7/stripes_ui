import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/History/EventView/entry_display.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class EventGrid extends ConsumerStatefulWidget {
  const EventGrid({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EventGridState();
}

class _EventGridState extends ConsumerState<EventGrid> {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
}
