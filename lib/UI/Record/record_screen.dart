import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
        child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(
              onPressed: () {},
              child: const Text('About'),
            ),
          ],
        ),
        const SizedBox(
          height: AppPadding.xxl,
        )
      ],
    ));
  }
}

class Options extends ConsumerWidget {
  const Options({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(testsHolderProvider);

    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final AsyncValue<List<RecordPath>> paths = ref.watch(recordPaths(
        const RecordPathProps(
            filterEnabled: true, type: PathProviderType.record)));
    final AsyncValue<List<CheckinItem>> checkins = ref.watch(
      checkInPaths(
        const CheckInPathsProps(),
      ),
    );

    final AsyncValue<TestsRepo?> repo = ref.watch(testProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: AppPadding.xl,
        ),
        AsyncValueDefaults(
            value: checkins,
            onData: (loadedCheckins) {
              final List<CheckinItem> translatedCheckins = loadedCheckins
                  .map((checkin) =>
                      localizations?.translateCheckin(checkin) ?? checkin)
                  .toList();
              return CheckinsPageView(
                checkins: translatedCheckins,
                additions: (item) {
                  return repo.valueOrNull?.getPathAdditions(context, item.type);
                },
              );
            }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
          child: AsyncValueDefaults(
              value: paths,
              onLoading: (_) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate.categorySelect,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.left,
                    ),
                    ...List.generate(
                      4,
                      (_) => Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppPadding.tiny),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: Breakpoint.small.value),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(AppRounding.small)),
                              color: Theme.of(context).disabledColor,
                            ),
                            height: 65.0,
                          ),
                        ),
                      ),
                    ).separated(
                        by: const SizedBox(
                      height: AppPadding.small,
                    ))
                  ],
                );
              },
              onData: (loadedPaths) {
                final List<RecordPath> translatedPaths = loadedPaths
                    .map((path) => localizations?.translatePath(path) ?? path)
                    .toList();
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.translate.categorySelect,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.left,
                      ),
                      ...translatedPaths.mapIndexed((index, path) {
                        final List<Widget> additions = repo.valueOrNull
                                ?.getPathAdditions(context, path.name) ??
                            [];

                        return RecordButton(path.name, (context) {
                          context.pushNamed('recordType', pathParameters: {
                            'type': loadedPaths[index].name
                          });
                        }, additions);
                      }),
                    ]);
              }),
        ),
        const SizedBox(
          height: AppPadding.xl,
        ),
      ],
    );
  }
}

class CheckinsPageView extends StatefulWidget {
  final List<CheckinItem> checkins;

  final List<Widget>? Function(CheckinItem) additions;

  const CheckinsPageView(
      {super.key, required this.checkins, required this.additions});

  @override
  State<StatefulWidget> createState() {
    return _CheckinsPageViewState();
  }
}

class _CheckinsPageViewState extends State<CheckinsPageView> {
  late ExpansibleController expansionController;
  late ScrollController scrollController;
  late List<CheckinItem> sorted;
  late bool hasCheckin;
  int currentPage = 0;
  late int count;
  double itemWidth = 280;

  @override
  void initState() {
    hasCheckin = false;
    count = 0;
    sorted = [];
    for (final CheckinItem item in widget.checkins) {
      if (item.response == null) {
        hasCheckin = true;
        count++;
        sorted.insert(0, item);
      } else {
        sorted.add(item);
      }
    }

    expansionController = ExpansibleController();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);

    if (!hasCheckin) {
      expansionController.collapse();
    } else {
      expansionController.expand();
    }

    super.initState();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final double offset = scrollController.offset;
    final int newPage =
        (offset / itemWidth).round().clamp(0, sorted.length - 1);
    if (newPage != currentPage) {
      setState(() {
        currentPage = newPage;
      });
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (sorted.isEmpty) return const SizedBox();

    return Expansible(
        headerBuilder: (context, animation) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (expansionController.isExpanded) {
                      expansionController.collapse();
                    } else {
                      expansionController.expand();
                    }
                  },
                  child: Row(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: Durations.medium1,
                        style: expansionController.isExpanded
                            ? Theme.of(context).textTheme.titleMedium!
                            : Theme.of(context).textTheme.bodySmall!,
                        child: Text(
                          "${context.translate.checkInLabel} (${widget.checkins.length - count}/${widget.checkins.length})",
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Icon(expansionController.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down)
                    ],
                  ),
                ),
                if (expansionController.isExpanded &&
                    currentPage < sorted.length)
                  Text(
                    sorted[currentPage]
                        .path
                        .period!
                        .getRangeString(DateTime.now(), context),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          );
        },
        bodyBuilder: (context, animation) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use available width for full-width items, or fixed width if smaller
                itemWidth = constraints.maxWidth > 300
                    ? constraints.maxWidth - AppPadding.small * 2
                    : 280;

                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: scrollController,
                    physics: const PageScrollPhysics(),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final CheckinItem item = sorted[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.tiny),
                        child: SizedBox(
                          width: itemWidth,
                          child: CheckInButton(
                            item: item,
                            additions: widget.additions(item) ?? [],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        controller: expansionController);
  }
}

class Header extends ConsumerWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.large),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(child: PatientChanger()),
          ],
        ),
      ]),
    );
  }
}

class LastEntryText extends ConsumerWidget {
  const LastEntryText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Stamp>> stamps = ref.watch(stampHolderProvider);
    return stamps.map(
        data: (data) {
          final String lastEntry = data.value.isEmpty
              ? context.translate.noEntryText
              : context.translate
                  .lastEntry(dateFromStamp(data.value.first.stamp));
          return Text(
            lastEntry,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        },
        error: (error) => Container(
              height: 10,
              width: 10,
              color: Theme.of(context).colorScheme.error,
            ),
        loading: (loading) => const CircularProgressIndicator());
  }
}

class CheckInButton extends ConsumerWidget {
  final CheckinItem item;
  final List<Widget> additions;

  const CheckInButton({required this.item, required this.additions, super.key});

  String _formatTimeRemaining(Duration duration, BuildContext context) {
    if (duration.isNegative) return '';
    if (duration.inDays > 0) {
      return '${duration.inDays}d remaining';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}h remaining';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m remaining';
    }
    return 'Ending soon';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isCompleted = item.response != null;
    final ColorScheme colors = Theme.of(context).colorScheme;

    // Calculate time remaining for pending check-ins
    final DateTimeRange range = item.path.period!.getRange(DateTime.now());
    final Duration timeRemaining = range.end.difference(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (item.response != null) {
                String? routeName = item.response!.type;
                context.pushNamed('recordType',
                    pathParameters: {'type': routeName},
                    extra: QuestionsListener(
                        responses: item.response!.responses,
                        editId: item.response?.id,
                        submitTime: dateFromStamp(item.response!.stamp),
                        desc: item.response!.description));
              } else {
                context.pushNamed(
                  'recordType',
                  pathParameters: {'type': item.type},
                );
              }
            },
            borderRadius: BorderRadius.circular(AppRounding.medium),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRounding.medium),
                border: Border.all(
                  color: isCompleted
                      ? colors.primary.withValues(alpha: 0.3)
                      : colors.outlineVariant,
                  width: isCompleted ? 2 : 1,
                ),
                gradient: isCompleted
                    ? LinearGradient(
                        colors: [
                          colors.primaryContainer.withValues(alpha: 0.3),
                          colors.primaryContainer.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Row(
                children: [
                  // Check indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? colors.primary
                          : colors.surfaceContainerHighest,
                      border: isCompleted
                          ? null
                          : Border.all(color: colors.outline, width: 2),
                    ),
                    child: isCompleted
                        ? Icon(Icons.check, color: colors.onPrimary, size: 24)
                        : Icon(Icons.add,
                            color: colors.onSurfaceVariant, size: 24),
                  ),
                  const SizedBox(width: AppPadding.medium),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.path.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isCompleted
                                        ? colors.primary
                                        : colors.onSurface,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        if (isCompleted)
                          Text(
                            'Last updated ${_formatLastUpdated(item.response!.stamp, context)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                          )
                        else
                          Text(
                            _formatTimeRemaining(timeRemaining, context),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                          ),
                        if (additions.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          ...additions,
                        ],
                      ],
                    ),
                  ),

                  // Trailing icon
                  Icon(
                    Icons.chevron_right,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ).showCursorOnHover,
      ),
    );
  }

  String _formatLastUpdated(int stamp, BuildContext context) {
    final DateTime date = dateFromStamp(stamp);
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}

class CheckIndicator extends StatelessWidget {
  final bool checked;

  const CheckIndicator({required this.checked, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35,
      height: 35,
      child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRounding.small),
                border: Border.all(
                    width: 3.0, color: Theme.of(context).colorScheme.primary)),
            child: checked
                ? const SizedBox.expand(
                    child:
                        FittedBox(fit: BoxFit.fill, child: Icon(Icons.check)))
                : null,
          )),
    );
  }
}

class RecordButton extends StatelessWidget {
  final String text;
  final String? subText;
  final List<Widget> additions;
  final Function(BuildContext) onClick;

  const RecordButton(this.text, this.onClick, this.additions,
      {this.subText, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
            child: OutlinedButton(
              onPressed: () {
                onClick(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.small, vertical: AppPadding.large),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              text,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                            ),
                          ),
                          ...additions
                        ]),
                    const Icon(
                      Icons.add,
                      size: 35,
                    )
                  ],
                ),
              ),
            ).showCursorOnHover));
  }
}
