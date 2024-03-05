import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/PatientManagement/patient_changer.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class Footer extends StatelessWidget {
  const Footer({Key? key}) : super(key: key);

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
          height: 35,
        )
      ],
    ));
  }
}

class Options extends ConsumerWidget {
  const Options({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, RecordPath> recordPaths = ref.watch(recordProvider);
    final Map<Period, List<CheckinItem>> checkin =
        ref.watch(checkinProvider(null));
    final List<String> questionTypes = recordPaths.keys.toList();
    final TestsRepo? repo = ref.watch(testHolderProvider).repo;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            const SizedBox(
              height: 20.0,
            ),
            if (checkin.isNotEmpty)
              Text(
                AppLocalizations.of(context)!.checkInLabel,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ...checkin.keys.map((period) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period.getRangeString(DateTime.now(), context),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  ...checkin[period]!.map((checkin) => CheckInButton(
                        item: checkin,
                        additions:
                            repo?.getPathAdditions(context, checkin.type) ?? [],
                      ))
                ],
              );
            }),
            if (checkin.isNotEmpty)
              const Divider(
                height: 20,
                indent: 15,
                endIndent: 15,
                thickness: 2,
              ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                AppLocalizations.of(context)!.categorySelect,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.left,
              ),
              ...questionTypes.map((key) {
                final List<Widget> additions =
                    repo?.getPathAdditions(context, key) ?? [];

                return RecordButton(key, (context) {
                  context
                      .pushNamed('recordType', pathParameters: {'type': key});
                }, additions);
              }).toList(growable: false),
            ]),
            const Divider(
              height: 20,
              indent: 15,
              endIndent: 15,
              thickness: 2,
            ),
            const SizedBox(
              height: 20.0,
            ),
          ],
        ),
      ),
    );
  }
}

class Header extends ConsumerWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isSmall = MediaQuery.of(context).size.width < SMALL_LAYOUT;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Expanded(child: PatientChanger()),
              const SizedBox(
                width: 8.0,
              ),
              isSmall
                  ? const UserProfileButton()
                  : const SizedBox(
                      width: 35,
                    ),
            ],
          ),
          const SizedBox(
            height: 4.0,
          ),
          const LastEntryText(),
        ]),
      ),
    );
  }
}

class LastEntryText extends ConsumerWidget {
  const LastEntryText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Stamp> vals = ref.watch(stampHolderProvider).stamps;
    final String lastEntry = vals.isEmpty
        ? AppLocalizations.of(context)!.noEntryText
        : AppLocalizations.of(context)!
            .lastEntry(dateFromStamp(vals.first.stamp));
    return Text(
      lastEntry,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class CheckInButton extends ConsumerWidget {
  final CheckinItem item;
  final List<Widget> additions;

  const CheckInButton({required this.item, required this.additions, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SMALL_LAYOUT / 1.5),
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
                    horizontal: 10.0, vertical: 15.0),
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
      {this.subText, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SMALL_LAYOUT / 1.5),
            child: OutlinedButton(
              onPressed: () {
                onClick(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            text,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary),
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
