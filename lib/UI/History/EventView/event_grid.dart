import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/History/EventView/entry_display.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class EventGrid extends ConsumerWidget {
  const EventGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;

    final AsyncValue<Available> available = ref.watch(availibleStampsProvider);

    if (available.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (available.valueOrNull?.filteredVisible.isEmpty ?? true) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            AppLocalizations.of(context)!.noEventsText,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
            maxLines: null,
          ),
        ),
      );
    }

    final List<Response> availableStamps =
        available.valueOrNull?.filteredVisible ?? [];

    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
        sliver: isSmall
            ? SliverList(
                delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        EntryDisplay(event: availableStamps[index]),
                    childCount: availableStamps.length),
              )
            : SliverMasonryGrid(
                delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        EntryDisplay(event: availableStamps[index]),
                    childCount: availableStamps.length),
                gridDelegate:
                    const SliverSimpleGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                ),
              ),
      )
    ]);
  }
}
