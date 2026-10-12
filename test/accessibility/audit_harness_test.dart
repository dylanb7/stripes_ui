import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_harness.dart';

void main() {
  testWidgets('records overflow, truncation, and shrinking separately', (
    tester,
  ) async {
    final run = AuditRun(tester, 'detector-fixture', auditDevices.last, 2);
    run.start();
    try {
      await run.checkpoint(
        'broken-controls',
        () => tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [SizedBox(width: 200, height: 20)]),
                      Text(
                        'A long label that will be truncated',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('A long label forced into a small box'),
                      ),
                      Offstage(
                        child: Text(
                          'Hidden truncation must not be reported',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      run.stop();
    }
    expect(
      run.issues.map((i) => i['kind']),
      containsAll(['overflow', 'truncated-text', 'shrunk-text']),
    );
    expect(run.hasErrors, isTrue);
    expect(
      run.issues.any(
        (i) => i['message'].toString().contains('Hidden truncation'),
      ),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('unexpected framework errors are forwarded and recorded', (
    tester,
  ) async {
    final previous = FlutterError.onError;
    final forwarded = <FlutterErrorDetails>[];
    FlutterError.onError = forwarded.add;
    final run = AuditRun(tester, 'fixture', auditDevices.last, 1);
    run.start();
    try {
      FlutterError.reportError(
        FlutterErrorDetails(exception: StateError('Fixture failed to load')),
      );
    } finally {
      run.stop();
      FlutterError.onError = previous;
    }
    expect(forwarded, hasLength(1));
    expect(run.issues.single['kind'], 'framework-error');
    expect(run.hasErrors, isTrue);
  });

  testWidgets('review signals alone are not confirmed layout failures', (
    tester,
  ) async {
    final run = AuditRun(tester, 'fixture', auditDevices.last, 1);
    run.addIssue(
      kind: 'truncated-text',
      severity: 'review',
      message: 'Optional preview',
      source: 'fixture',
    );
    run.addIssue(
      kind: 'truncated-text',
      severity: 'review',
      message: 'Optional preview',
      source: 'fixture',
    );
    expect(run.issues, hasLength(1));
    expect(run.hasErrors, isFalse);
  });
}
