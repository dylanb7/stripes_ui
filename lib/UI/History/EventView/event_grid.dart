import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/Util/constants.dart';

class EventGrid extends ConsumerWidget {
  const EventGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;

    final AsyncValue<List<Response>> available = ref.watch(
        availibleStampsProvider.select((value) => value.hasValue
            ? AsyncValue.data(value.valueOrNull!.filteredVisible)
            : const AsyncLoading<List<Response>>()));

    if (available.isLoading) {
      return const SliverToBoxAdapter(child: LoadingWidget());
    }

    if (available.valueOrNull!.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 25.0,
        ),
      );
    }

    final List<Response> availableStamps = available.valueOrNull ?? [];

    return SliverPadding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
      sliver: isSmall
          ? SliverList(
              delegate: SliverChildBuilderDelegate(
                  (context, index) => EntryDisplay(
                      event: availableStamps[
                          (availableStamps.length - 1) - index]),
                  childCount: availableStamps.length),
            )
          : SliverMasonryGrid(
              delegate: SliverChildBuilderDelegate(
                  (context, index) => EntryDisplay(
                      event: availableStamps[
                          (availableStamps.length - 1) - index]),
                  childCount: availableStamps.length),
              gridDelegate:
                  const SliverSimpleGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
              ),
            ),
    );
  }
}
