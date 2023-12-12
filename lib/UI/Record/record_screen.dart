import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/PatientManagement/patient_changer.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/question_splitter.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/UI/Record/symptom_record_data.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/Util/text_styles.dart';
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
    final TestState state = ref.watch(testHolderProvider).state;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            const SizedBox(
              height: 20.0,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.categorySelect,
                style: darkBackgroundHeaderStyle,
                textAlign: TextAlign.left,
              ),
            ),
            ...questionTypes.map((key) {
              if (key != Symptoms.BM ||
                  (state != TestState.logs && state != TestState.logsSubmit)) {
                return RecordButton(key, (context) {
                  context
                      .pushNamed('recordType', pathParameters: {'type': key});
                });
              }
              return RecordButton(
                key,
                (context) {
                  context
                      .pushNamed('recordType', pathParameters: {'type': key});
                },
                subText: AppLocalizations.of(context)!.testInProgressNotif,
              );
            }).toList(growable: false),
            const SizedBox(
              height: 20.0,
            ),
            const Divider(
              height: 2,
              indent: 15,
              endIndent: 15,
              thickness: 2,
            ),
            const SizedBox(
              height: 20.0,
            ),
            ...checkin.keys.map((period) {
              return Column(
                children: [
                  Text(
                    period.getRangeString(DateTime.now(), context),
                    style: darkBackgroundHeaderStyle,
                  ),
                  ...checkin[period]!.map((checkin) => CheckInButton(
                        item: checkin,
                      ))
                ],
              );
            })
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
      style: darkBackgroundStyle.copyWith(fontSize: 16.0),
    );
  }
}

class CheckInButton extends ConsumerWidget {
  final CheckinItem item;

  const CheckInButton({required this.item, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DetailResponse? sub =
        item.response != null ? item.response as DetailResponse : null;

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SMALL_LAYOUT / 1.5),
            child: OutlinedButton(
              onPressed: () {
                if (sub != null) {
                  String? routeName = sub.type;

                  final QuestionsListener questionsListener =
                      QuestionsListener();
                  for (Response res
                      in (item.response as DetailResponse).responses) {
                    questionsListener.addResponse(res);
                  }

                  context.pushNamed('recordType',
                      pathParameters: {'type': routeName},
                      extra: SymptomRecordData(
                          isEdit: true,
                          editId: sub.id,
                          listener: questionsListener,
                          submitTime: dateFromStamp(sub.stamp),
                          initialDesc: sub.description));
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
                    Text(item.type, style: lightBackgroundHeaderStyle),
                    CheckIndicator(
                      checked: sub != null,
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
  final Function(BuildContext) onClick;

  const RecordButton(this.text, this.onClick, {this.subText, Key? key})
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
                    if (subText != null && subText!.isNotEmpty)
                      Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: lightBackgroundHeaderStyle,
                            ),
                            Text(
                              subText!,
                              style: lightBackgroundStyle.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                            ),
                          ]),
                    if (subText == null || subText!.isEmpty)
                      Text(text, style: lightBackgroundHeaderStyle),
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
