import 'dart:async';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_dye_test_screen.dart';
import 'package:stripes_ui/Util/extensions.dart';

final Map<SubUser, BlueDyeState?> _repo = {};

class BlueDyeTest extends Test<BlueDyeState> {
  final BlueDyeState blueDye = BlueDyeState.empty();

  final BehaviorSubject<BlueDyeState> _streamController = BehaviorSubject();

  BlueDyeTest(
      {required super.stampRepo,
      required super.authUser,
      required super.subUser,
      required super.questionRepo})
      : super(listensTo: {Symptoms.BM}, testName: "Blue Dye Test") {
    if (_repo[subUser] == null) {
      _repo[subUser] = BlueDyeState.empty();
    }
  }

  setStart(DateTime time) {
    _repo[subUser] = _repo[subUser]?.copyWith(startTime: time) ??
        BlueDyeState(logs: [], startTime: time);
    _streamController.add(_repo[subUser]!);
  }

  finishedEating(Duration time) {
    _repo[subUser]?.finishedEating = time;
  }

  @override
  String getName(BuildContext context) {
    return context.translate.blueDyeHeader;
  }

  @override
  BehaviorSubject<BlueDyeState> get state => _streamController;

  BlueDyeTestStage get testStage => state.hasValue
      ? stageFromTestState(state.value)
      : BlueDyeTestStage.initial;

  @override
  Future<void> onDelete(Response<Question> stamp, String type) async {
    if (stamp is! DetailResponse || !_repo.containsKey(subUser)) return;
    final BlueDyeState current = _repo[subUser]!;
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
    final BlueDyeState current = _repo[subUser]!;
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
    final BlueDyeState? current = _repo[subUser];
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
    final BlueDyeTestStage current = testStage;
    if (current == BlueDyeTestStage.initial ||
        current == BlueDyeTestStage.started) {
      return null;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.0,
          color: Theme.of(context).colorScheme.secondary.darken(),
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(6.0),
        ),
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          context.translate.testInProgressNotif,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary.darken()),
        ),
      ),
    );
  }

  @override
  List<Question> recordAdditions(BuildContext context, String type) {
    final BlueDyeTestStage current = testStage;
    return [
      if (current == BlueDyeTestStage.logs ||
          current == BlueDyeTestStage.logsSubmit)
        MultipleChoice(
            id: blueQuestionId,
            isRequired: true,
            prompt: context.translate.submitBlueQuestion,
            type: type,
            choices: [
              context.translate.blueQuestionYes,
              context.translate.blueQuestionNo
            ])
    ];
  }

  @override
  Future<bool> cancel() async {
    _repo[subUser] = BlueDyeState.empty();
    _streamController.add(BlueDyeState.empty());
    return true;
  }

  @override
  Future<bool> setTestState(BlueDyeState state) async {
    _repo[subUser] = state;
    _streamController.add(_repo[subUser]!);
    return true;
  }

  @override
  Future<bool> submit(DateTime submitTime) async {
    stampRepo.addStamp(BlueDyeResp.from(_repo[subUser]!));
    cancel();
    return true;
  }

  @override
  Widget? displayState(BuildContext context) {
    return const BlueDyeTestScreen();
  }

  @override
  Future<void> refresh() async {}
}

const blueQuestionId = "BlueDyeQuestion";
