import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_changer.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Widgets/mouse_hover.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
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
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);
    final AsyncValue<List<BaselineRecordItem>> paths =
        ref.watch(availableRecordPaths);
    final AsyncValue<List<ReviewItem>> checkins = ref.watch(
      reviewPaths(
        const ReviewPathsProps(),
      ),
    );

    final AsyncValue<TestsState> testsState = ref.watch(testsHolderProvider);
    final TestsRepo? repo = testsState.valueOrNull?.testsRepo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: AppPadding.xl,
        ),
        AsyncValueDefaults(
            value: checkins,
            onData: (loadedReviews) {
              final List<ReviewItem> translatedReviews = loadedReviews
                  .map((review) =>
                      localizations?.translateReview(review) ?? review)
                  .toList();
              return ReviewsPageView(
                reviews: translatedReviews,
                additions: (item) {
                  return repo?.getPathAdditions(context, item.type);
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
              onData: (loadedItems) {
                // Translate record paths inside items
                final List<BaselineRecordItem> translatedItems = loadedItems
                    .map((item) => BaselineRecordItem(
                        path: localizations?.translatePath(item.path) ??
                            item.path,
                        baseline: item.baseline))
                    .toList();

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.translate.categorySelect,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.left,
                      ),
                      ...translatedItems.mapIndexed((index, item) {
                        final String unlocalizedPathName =
                            loadedItems[index].path.name;
                        final List<Widget> additions = repo?.getPathAdditions(
                                context, unlocalizedPathName) ??
                            [];
                        return RecordButton(item.path.name, (context) async {
                          await context.pushNamed('recordType',
                              pathParameters: {'type': unlocalizedPathName},
                              extra: item.baseline);
                          if (context.mounted) {
                            ref.invalidate(stampsStreamProvider);
                          }
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

class ReviewsPageView extends StatefulWidget {
  final List<ReviewItem> reviews;

  final List<Widget>? Function(ReviewItem) additions;

  const ReviewsPageView(
      {super.key, required this.reviews, required this.additions});

  @override
  State<StatefulWidget> createState() {
    return _ReviewsPageViewState();
  }
}

class _ReviewsPageViewState extends State<ReviewsPageView> {
  late ExpansibleController expansionController;
  PageController? _pageController;
  double? _lastViewportFraction;

  late List<ReviewItem> sorted;
  late bool hasCheckin;
  int currentPage = 0;
  late int count;
  double itemWidth = 280;

  @override
  void initState() {
    hasCheckin = false;
    count = 0;
    sorted = [];
    for (final ReviewItem item in widget.reviews) {
      if (item.response == null) {
        hasCheckin = true;
        count++;
        sorted.insert(0, item);
      } else {
        sorted.add(item);
      }
    }

    expansionController = ExpansibleController();

    if (!hasCheckin) {
      expansionController.collapse();
    } else {
      expansionController.expand();
    }

    super.initState();
  }

  @override
  void dispose() {
    _pageController?.dispose();
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
                      Row(
                        children: [
                          Icon(
                            Icons.event_repeat,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppPadding.tiny),
                          AnimatedDefaultTextStyle(
                            duration: Durations.medium1,
                            style: expansionController.isExpanded
                                ? Theme.of(context).textTheme.titleMedium!
                                : Theme.of(context).textTheme.bodySmall!,
                            child: Text(
                              "${context.translate.checkInLabel} (${widget.reviews.length - count}/${widget.reviews.length})",
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
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
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use available width for full-width items, or fixed width if smaller
                itemWidth = constraints.maxWidth > 340
                    ? constraints.maxWidth -
                        (AppPadding.medium * 2) -
                        AppPadding.small
                    : 280;

                final double viewportFraction =
                    (itemWidth / constraints.maxWidth).clamp(0.1, 1.0);

                if (_pageController == null ||
                    (_lastViewportFraction != null &&
                        (_lastViewportFraction! - viewportFraction).abs() >
                            0.001)) {
                  final oldController = _pageController;
                  _pageController = PageController(
                      viewportFraction: viewportFraction,
                      initialPage: currentPage);
                  oldController?.dispose();
                  _lastViewportFraction = viewportFraction;
                }

                return SizedBox(
                  height: 100,
                  child: PageView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: _pageController,
                    itemCount: sorted.length,
                    padEnds: false, // Align start
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final ReviewItem item = sorted[index];
                      // Add padding to simulate gap, adjusted by viewport fraction logic implicitly
                      return Padding(
                        padding: const EdgeInsets.only(right: AppPadding.small),
                        child: SizedBox(
                          width: itemWidth,
                          child: ReviewButton(
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
    final AsyncValue<List<Stamp>> stamps = ref.watch(stampsStreamProvider);
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

class ReviewButton extends ConsumerWidget {
  final ReviewItem item;
  final List<Widget> additions;

  const ReviewButton({required this.item, required this.additions, super.key});

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
            onTap: () async {
              if (item.response != null) {
                String? routeName = item.response!.type;
                await context.pushNamed('recordType',
                    pathParameters: {'type': routeName},
                    extra: QuestionsListener(
                        responses: item.response!.responses,
                        editId: item.response?.id,
                        submitTime: dateFromStamp(item.response!.stamp),
                        description: item.response!.description));
              } else {
                await context.pushNamed(
                  'recordType',
                  pathParameters: {'type': item.type},
                );
              }
              if (context.mounted) {
                ref.invalidate(stampsStreamProvider);
              }
            },
            borderRadius: BorderRadius.circular(AppRounding.medium),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRounding.medium),
                border: Border.all(
                  color: isCompleted
                      ? colors.outlineVariant.withValues(alpha: 0.5)
                      : colors.primary,
                  width: isCompleted ? 1 : 2,
                ),
                color: isCompleted ? colors.surfaceContainerLow : null,
                gradient: isCompleted
                    ? null
                    : LinearGradient(
                        colors: [
                          colors.primaryContainer.withValues(alpha: 0.4),
                          colors.primaryContainer.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              padding: const EdgeInsets.all(AppPadding.small),
              child: Row(
                children: [
                  // Check indicator
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? colors.surfaceContainerHighest
                          : colors.primary,
                      border: isCompleted
                          ? Border.all(color: colors.outlineVariant, width: 1)
                          : null,
                    ),
                    child: isCompleted
                        ? Icon(Icons.check, color: colors.outline, size: 20)
                        : Icon(Icons.add, color: colors.onPrimary, size: 24),
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
                                        ? colors.onSurfaceVariant
                                        : colors.onSurface,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        if (isCompleted)
                          Text(
                            'Completed ${_formatLastUpdated(item.response!.stamp, context)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.outline,
                                    ),
                          )
                        else
                          Text(
                            _formatTimeRemaining(timeRemaining, context),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w500,
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
