import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_ui/Providers/graph_data_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/Util/paddings.dart';

import 'freq_expand.dart';
import 'frequency_row.dart';

class EventFrequency extends ConsumerWidget {
  final int behaviorsDisplayed;

  const EventFrequency({this.behaviorsDisplayed = 3, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<CategoryBehaviorMaps> freqFetch = ref.watch(resMapProvider);

    final CategoryBehaviorMaps? freqs = freqFetch.whenOrNull(
      data: (data) => data,
    );

    if (freqs == null) {
      return const Center(
        child: LoadingWidget(),
      );
    }

    if (freqs == CategoryBehaviorMaps.empty()) {
      return const SizedBox.shrink();
    }

    Map<String, int> catMap = freqs.categoryMap;

    final double maxLengthCat = catMap.values.first.toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: AppPadding.medium,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Events by Category',
            maxLines: 1,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(
          height: AppPadding.small,
        ),
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRounding.medium)),
          child: Column(
            children: [
              const SizedBox(
                height: AppPadding.tiny,
              ),
              ...catMap.keys.map((key) {
                final int catVal = catMap[key]!;
                final Map<String, int> prompts =
                    freqs.categoryBehaviorMap[key] ?? {};
                final List<String> promptKeys = prompts.keys.toList();
                final Map<String, int> displayed = {
                  for (int i = 0;
                      i < min(promptKeys.length, behaviorsDisplayed);
                      i++)
                    promptKeys[i]: prompts[promptKeys[i]]!
                };
                if (displayed.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        left: AppPadding.small, right: AppPadding.xxl),
                    child: FrequencyRow(
                        percent: catVal.toDouble() / maxLengthCat,
                        amount: catVal,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.9),
                        hasTooltip: false,
                        prompt: key),
                  );
                }

                final double maxPromptLength =
                    displayed.values.first.toDouble();

                return FreqExpandible(
                  header: FrequencyRow(
                      percent: catVal.toDouble() / maxLengthCat,
                      amount: catVal,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.9),
                      hasTooltip: false,
                      prompt: key),
                  view: Padding(
                    padding: const EdgeInsets.only(
                        left: AppPadding.xl, right: AppPadding.xl),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Common Behaviors:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ...displayed.keys.map((key) {
                            final int promptVal = displayed[key]!;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: FrequencyRow(
                                amount: promptVal,
                                percent: promptVal.toDouble() / maxPromptLength,
                                prompt: key,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.6),
                              ),
                            );
                          }),
                        ]),
                  ),
                );
              }),
              const SizedBox(
                height: AppPadding.small,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
