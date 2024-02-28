import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

final Map<SubUser, BlueDyeObj?> _repo = {};

class BlueDyeTest extends Test<BlueDyeObj> {
  final BlueDyeObj blueDye = BlueDyeObj.empty();

  final BehaviorSubject<BlueDyeObj> _streamController = BehaviorSubject();

  BlueDyeTest(
      {required super.stampRepo,
      required super.authUser,
      required super.subUser,
      required super.questionRepo})
      : super(listensTo: {Symptoms.BM}) {
    if (_repo[subUser] == null) {
      _repo[subUser] = BlueDyeObj.empty();
    }
  }

  setStart(DateTime time) {
    _repo[subUser] = _repo[subUser]?.copyWith(startTime: time) ??
        BlueDyeObj(logs: [], startTime: time);
    _streamController.add(_repo[subUser]!);
  }

  finishedEating(Duration time) {
    _repo[subUser]?.finishedEating = time;
  }

  @override
  String getName(BuildContext context) {
    return AppLocalizations.of(context)!.blueDyeHeader;
  }

  @override
  BehaviorSubject<BlueDyeObj> get obj => _streamController;

  TestState get state =>
      obj.hasValue ? stateFromTestOBJ(obj.value) : TestState.initial;

  @override
  Future<void> onDelete(Response<Question> stamp, String type) async {
    if (stamp is! DetailResponse || !_repo.containsKey(subUser)) return;
    final BlueDyeObj current = _repo[subUser]!;
    final List<BMTestLog> logs = current.logs;
    final List<BMTestLog> newLogs =
        logs.where((log) => log.response.stamp != stamp.stamp).toList();
    if (newLogs.length == logs.length) return;

    _repo[subUser] = current.copyWith(logs: newLogs);
    _streamController.add(_repo[subUser]!);
  }

  @override
  Future<void> onEdit(Response<Question> stamp, String type) async {
    if (stamp is! DetailResponse || !_repo.containsKey(subUser)) return;
    final BlueDyeObj current = _repo[subUser]!;
    final List<BMTestLog> logs = current.logs;
    for (int i = 0; i < logs.length; i++) {
      if (stamp.stamp == logs[i].response.stamp) {
        final bool? blue = _isBlueFromDetail(stamp);
        if (blue == null) return;
        logs[i] = BMTestLog(response: stamp, isBlue: blue);
        _repo[subUser] = current.copyWith(logs: logs);
        _streamController.add(_repo[subUser]!);
        return;
      }
    }
  }

  @override
  Future<void> onSubmit(Response<Question> stamp, String type) async {
    if (stamp is! DetailResponse) return;
    final bool? blue = _isBlueFromDetail(stamp);
    if (blue == null) return;
    final BlueDyeObj? current = _repo[subUser];
    _repo[subUser] = current?.copyWith(
        logs: [...current.logs, BMTestLog(response: stamp, isBlue: blue)]);
    _streamController.add(_repo[subUser]!);
  }

  bool? _isBlueFromDetail(DetailResponse res) {
    List<Response> blueRes = res.responses
        .where((val) => val.question.id == blueQuestionId)
        .toList();
    if (blueRes.isEmpty) return null;
    final MultiResponse multi = blueRes.first as MultiResponse;
    return multi.index == 0;
  }

  @override
  Widget? pathAdditions(BuildContext context, String type) {
    final TestState current = state;
    if (current == TestState.initial || current == TestState.started) {
      return null;
    }
    return Text(
      AppLocalizations.of(context)!.testInProgressNotif,
      style: lightBackgroundStyle.copyWith(
          color: Theme.of(context).colorScheme.secondary),
    );
  }

  @override
  List<Question> recordAdditions(BuildContext context, String type) {
    final TestState current = state;
    return [
      if (current == TestState.logs || current == TestState.logsSubmit)
        MultipleChoice(
            id: blueQuestionId,
            isRequired: true,
            prompt: AppLocalizations.of(context)!.submitBlueQuestion,
            type: type,
            choices: [
              AppLocalizations.of(context)!.blueQuestionYes,
              AppLocalizations.of(context)!.blueQuestionNo
            ])
    ];
  }

  @override
  Future<void> cancel() async {
    _repo[subUser] = BlueDyeObj.empty();
    _streamController.add(BlueDyeObj.empty());
  }

  @override
  Future<void> setValue(BlueDyeObj obj) async {
    _repo[subUser] = obj;
    _streamController.add(_repo[subUser]!);
  }

  @override
  Future<void> submit(DateTime submitTime) async {
    stampRepo.addStamp(BlueDyeResp.from(_repo[subUser]!));
    cancel();
  }

  @override
  Widget? displayState(BuildContext context) {
    return BlueDyeTestScreen();
  }
}

const blueQuestionId = "BlueDyeQuestion";
