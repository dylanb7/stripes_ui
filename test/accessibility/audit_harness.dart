import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const auditBoundaryKey = ValueKey('text-size-audit');

class AuditDevice {
  final String name;
  final Size size;
  final EdgeInsets insets;
  const AuditDevice(this.name, this.size, this.insets);
}

const auditDevices = [
  AuditDevice('compact', Size(320, 568), EdgeInsets.only(top: 20)),
  AuditDevice('mini', Size(375, 812), EdgeInsets.only(top: 50, bottom: 34)),
];

Future<void> loadAuditFonts() async {
  final loader = FontLoader('Inter')
    ..addFont(
      rootBundle.load(
        'packages/stripes_ui/assets/fonts/Inter/Inter-VariableFont_slnt,wght.ttf',
      ),
    );
  await loader.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

/// Discovery only: expected layout overflows are recorded so later cases run.
/// Unexpected framework errors still reach Flutter's test handler and fail.
class AuditRun {
  final WidgetTester tester;
  final String screen;
  final AuditDevice device;
  final double scale;
  final Directory? output;
  final List<Map<String, Object?>> issues = [];
  final List<Map<String, Object?>> captures = [];
  void Function(FlutterErrorDetails)? _previousHandler;
  String stage = 'initial';

  AuditRun(this.tester, this.screen, this.device, this.scale, {this.output});

  String get id => '$screen-${device.name}-${scale}x';
  bool get hasErrors => issues.any((issue) => issue['severity'] == 'error');

  void start() {
    _previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      final overflow = message.contains('overflowed by');
      final diagnostics = details.toString();
      final source = RegExp(r'lib/[^\s():]+\.dart:\d+(?::\d+)?')
          .firstMatch(diagnostics)
          ?.group(0);
      addIssue(
        kind: overflow ? 'overflow' : 'framework-error',
        severity: 'error',
        message: message,
        source: source ?? screen,
        detail: diagnostics,
      );
      if (!overflow) _previousHandler?.call(details);
    };
  }

  void stop() => FlutterError.onError = _previousHandler;

  void addIssue({
    required String kind,
    required String severity,
    required String message,
    required String source,
    String? detail,
  }) {
    if (issues.any(
      (issue) =>
          issue['stage'] == stage &&
          issue['kind'] == kind &&
          issue['message'] == message &&
          issue['source'] == source,
    )) {
      return;
    }
    issues.add({
      'stage': stage,
      'kind': kind,
      'severity': severity,
      'message': message,
      'source': source,
      'detail': detail,
    });
  }

  Future<void> checkpoint(String name, Future<void> Function() action) async {
    stage = name;
    await action();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    inspectText();
    String? filename;
    if (output != null) {
      filename = '$id-${captures.length}-$name.png';
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(auditBoundaryKey),
      );
      // Image encoding needs real async time outside the widget test clock.
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('${output!.path}/$filename').writeAsBytesSync(
            bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        } finally {
          image.dispose();
        }
      });
    }
    captures.add({'stage': name, 'image': filename});
  }

  /// Walk the visible paragraphs. Ellipsis and fitted text are review signals,
  /// not proof of an accessibility failure (some truncation is intentional).
  void inspectText() {
    final viewport = Offset.zero & device.size;
    for (final element in find.byType(RichText).evaluate()) {
      final render = element.renderObject;
      if (render is! RenderParagraph || !render.hasSize) continue;
      final bounds = MatrixUtils.transformRect(
        render.getTransformTo(null),
        Offset.zero & render.size,
      );
      if (bounds.isEmpty || !bounds.overlaps(viewport)) continue;
      var hidden = false;
      element.visitAncestorElements((ancestor) {
        final widget = ancestor.widget;
        if ((widget is Offstage && widget.offstage) ||
            (widget is Opacity && widget.opacity == 0) ||
            (widget is FadeTransition && widget.opacity.value == 0)) {
          hidden = true;
          return false;
        }
        return true;
      });
      if (hidden) continue;
      final text = render.text.toPlainText();
      if (text.trim().isEmpty) continue;
      final chain = element.debugGetCreatorChain(12);
      if (render.didExceedMaxLines) {
        addIssue(
          kind: 'truncated-text',
          severity: 'review',
          message: text,
          source: screen,
          detail: chain,
        );
      }
      // Detect text scaled down by FittedBox without a RenderFlex error.
      RenderObject? ancestor = render.parent;
      while (ancestor != null) {
        if (ancestor is RenderFittedBox && ancestor.child != null) {
          final transform = ancestor.child!.getTransformTo(ancestor).storage;
          final factor = math.sqrt(
            transform[0] * transform[0] + transform[1] * transform[1],
          );
          if (factor < 0.98) {
            addIssue(
              kind: 'shrunk-text',
              severity: 'review',
              message: text,
              source: screen,
              detail:
                  'FittedBox paints at ${(factor * 100).round()}% of '
                  'the requested text size. $chain',
            );
          }
          break;
        }
        ancestor = ancestor.parent;
      }
    }
  }

  Map<String, Object?> toJson() => {
    'screen': screen,
    'device': device.name,
    'width': device.size.width,
    'height': device.size.height,
    'scale': scale,
    'issues': issues,
    'captures': captures,
  };
}

class AuditReport {
  final Directory output;
  final List<AuditRun> runs = [];
  AuditReport(String path)
    : output = Directory(path)..createSync(recursive: true);

  void write() {
    final data = runs.map((run) => run.toJson()).toList();
    File('${output.path}/report.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    final json = jsonEncode(data).replaceAll('<', r'\u003c');
    File('${output.path}/index.html')
        .writeAsStringSync(_html.replaceFirst('/*AUDIT_DATA*/[]', json));
    final buffer = StringBuffer('# Text size audit\n\n')
      ..writeln(
        'Generated from deterministic fixtures with Inter, iOS theme, '
        'and linear text scaling. 3× is a stress case, not an iOS category.\n',
      )
      ..writeln(
        '${runs.length} cases; '
        '${runs.where((run) => run.hasErrors).length} with layout/framework '
        'errors. Review signals require visual triage.\n',
      )
      ..writeln('| Screen | Device | Scale | Errors | Review signals |')
      ..writeln('| --- | --- | --- | --- | --- |');
    for (final run in runs) {
      buffer.writeln(
        '| ${run.screen} | ${run.device.name} | ${run.scale}× | '
        '${run.issues.where((i) => i['severity'] == 'error').length} | '
        '${run.issues.where((i) => i['severity'] == 'review').length} |',
      );
    }
    buffer.writeln(
      '\nOpen index.html for screenshots, source locations, '
      'and per-state diagnostics. See test/accessibility/README.md for '
      'coverage and limitations.',
    );
    File('${output.path}/report.md').writeAsStringSync(buffer.toString());
  }
}

const _html = r'''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>STRiPES text size audit</title>
<style>
body{font:16px/1.5 system-ui;margin:24px;background:#f4f6f8;color:#152331}
h1{margin-bottom:4px}p{max-width:1000px}nav{display:flex;gap:16px;flex-wrap:wrap;position:sticky;top:0;background:#f4f6f8;padding:16px 0;z-index:1}
select{font:inherit;padding:6px}section{background:white;padding:20px;margin:24px 0;border:1px solid #ced6df;border-radius:10px}
.gallery{display:flex;gap:20px;overflow:auto;align-items:flex-start}figure{margin:0;flex:none;width:320px}img{width:100%;border:1px solid #ccc}figcaption{font-weight:600}
.error{color:#a12020}.review{color:#775200}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px;max-height:300px;overflow:auto}li{margin:8px 0}summary{cursor:pointer}table{border-collapse:collapse}td,th{padding:8px;text-align:left;border-bottom:1px solid #ddd}
</style><h1>STRiPES text size audit</h1>
<p>Actual screen widgets with deterministic fixture data and Inter. Linear scales are stress tests, not exact Dynamic Type categories. Errors are confirmed framework/layout failures; review signals identify truncated or shrunken text. Screenshots still need human review for overlap, clipping, and reachability. The Rive logo is represented by a fixed placeholder.</p>
<nav><label>Screen <select id="screen"></select></label><label>Device <select id="device"></select></label><label>Scale <select id="scale"></select></label><label><input type="checkbox" id="issues"> Only cases with findings</label></nav>
<p id="summary"></p><details><summary>Recurring error locations in this selection</summary><table><thead><tr><th>Source</th><th>Affected cases</th><th>First tested scale</th></tr></thead><tbody id="locations"></tbody></table></details><main id="results"></main>
<script>
const runs=/*AUDIT_DATA*/[];
const el=(tag,text)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;return n};
for(const field of ['screen','device','scale']){
 const select=document.getElementById(field);select.append(new Option('All',''));
 for(const value of [...new Set(runs.map(r=>r[field]))])select.append(new Option(value,value));
 select.addEventListener('change',render);
}
document.getElementById('issues').addEventListener('change',render);
function render(){
 const selected=runs.filter(r=>['screen','device','scale'].every(f=>!document.getElementById(f).value||String(r[f])===document.getElementById(f).value)&&(!document.getElementById('issues').checked||r.issues.length));
 document.getElementById('summary').textContent=`${selected.length} cases · ${selected.filter(r=>r.issues.some(i=>i.severity==='error')).length} with errors · ${selected.filter(r=>r.issues.some(i=>i.severity==='review')).length} needing text review`;
 const groups=new Map();
 for(const r of selected)for(const source of new Set(r.issues.filter(i=>i.severity==='error').map(i=>i.source))){const g=groups.get(source)||{count:0,scale:Infinity};g.count++;g.scale=Math.min(g.scale,r.scale);groups.set(source,g);}
 const locations=document.getElementById('locations');locations.replaceChildren();
 for(const [source,g] of [...groups].sort((a,b)=>b[1].count-a[1].count)){const tr=el('tr');for(const v of [source,g.count,g.scale+'×'])tr.append(el('td',v));locations.append(tr);}
 const root=document.getElementById('results');root.replaceChildren();
 for(const r of selected){
  const section=el('section');section.append(el('h2',`${r.screen} · ${r.device} (${r.width} × ${r.height}) · ${r.scale}×`));
  const gallery=el('div');gallery.className='gallery';
  for(const c of r.captures){const figure=el('figure');figure.append(el('figcaption',c.stage));if(c.image){const a=el('a');a.href=c.image;a.target='_blank';const img=el('img');img.loading='lazy';img.src=c.image;img.alt=`${r.screen}, ${c.stage}, ${r.scale}×`;a.append(img);figure.append(a);}gallery.append(figure);}
  section.append(gallery);
  if(!r.issues.length)section.append(el('p','No automated findings in the exercised states. Visual review still required.'));
  const list=el('ul');for(const i of r.issues){const li=el('li');li.className=i.severity;li.append(el('strong',`${i.stage} · ${i.kind}: `),document.createTextNode(i.message));const details=el('details');details.append(el('summary',i.source),el('pre',i.detail||''));li.append(details);list.append(li);}section.append(list);root.append(section);
 }
}render();
</script></html>''';
