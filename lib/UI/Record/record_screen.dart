import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
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
    final AsyncValue<List<RecordPath>> paths = ref.watch(recordPaths(
        const RecordPathProps(
            filterEnabled: true, type: PathProviderType.record)));
    final AsyncValue<List<CheckinItem>> checkins =
        ref.watch(checkInPaths(null));

    final AsyncValue<TestsRepo?> repo = ref.watch(testProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
      child: Column(
        children: [
          const SizedBox(
            height: AppPadding.xl,
          ),
          AsyncValueDefaults(
              value: checkins,
              onData: (loadedCheckins) {
                return CheckinsPageView(
                  checkins: loadedCheckins,
                  additions: (item) {
                    return repo.valueOrNull
                        ?.getPathAdditions(context, item.type);
                  },
                );
              }),
          AsyncValueDefaults(
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
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.translate.categorySelect,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.left,
                      ),
                      ...loadedPaths.map((path) {
                        final List<Widget> additions = repo.valueOrNull
                                ?.getPathAdditions(context, path.name) ??
                            [];

                        return RecordButton(path.name, (context) {
                          context.pushNamed('recordType',
                              pathParameters: {'type': path.name});
                        }, additions);
                      }),
                    ]);
              }),
          const SizedBox(
            height: AppPadding.xl,
          ),
        ],
      ),
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

  late PageController pageController;

  late List<CheckinItem> sorted;

  late bool hasCheckin;

  late int count;

  @override
  void initState() {
    hasCheckin = false;
    count = 0;
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

    pageController = PageController();

    if (!hasCheckin) {
      expansionController.collapse();
    }

    pageController.addListener(() {
      if (mounted) setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.checkins.isEmpty) return const SizedBox();
    return Expansible(
        headerBuilder: (context, animation) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedDefaultTextStyle(
                duration: Durations.medium1,
                style: expansionController.isExpanded
                    ? Theme.of(context).textTheme.titleMedium!
                    : Theme.of(context).textTheme.bodySmall!,
                child: Text(
                  "${context.translate.checkInLabel} ($count/${widget.checkins.length})",
                  textAlign: TextAlign.left,
                ),
              ),
              if (expansionController.isExpanded)
                Text(
                  widget
                      .checkins[pageController.page?.round() ?? 0].path.period!
                      .getRangeString(DateTime.now(), context),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          );
        },
        bodyBuilder: (context, animation) {
          return PageView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.checkins.length,
              controller: pageController,
              itemBuilder: (context, index) {
                final CheckinItem item = widget.checkins[index];
                return CheckInButton(
                    item: item, additions: widget.additions(item) ?? []);
              });
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.tiny),
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
            child: OutlinedButton(
              onPressed: () {
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
                          Text(item.type,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                          ...additions
                        ]),
                    CheckIndicator(
                      checked: item.response != null,
                    )
                  ],
                ),
              ),
            ).showCursorOnHover));
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
