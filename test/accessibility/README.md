# Text size audit

Run from the package root:

```sh
flutter test test/accessibility/text_size_audit.dart
```

Open **build/text_size_audit/index.html** in a browser. It is a standalone,
filterable gallery: choose a screen, device, or scale; compare screenshots;
expand an issue to see Flutter's source location and diagnostics. The recurring
location table counts affected cases, so one shared component need not become
dozens of separate tickets. PNGs, `report.json`, and `report.md` live alongside
the HTML. These generated artifacts are ignored by git.

This is a **discovery suite**. A successful test run means the scenarios ran,
not that accessibility passed. Expected RenderFlex overflows are collected so
the rest of the matrix still runs. Unexpected framework errors, missing fixture
widgets, and failed interactions fail normally. Use strict mode to fail a case
on its recorded errors, while still producing the report:

```sh
flutter test test/accessibility/text_size_audit.dart --dart-define=A11Y_STRICT=true
```

For focused iteration, filter by test name and save to another directory to
preserve the full report:

```sh
flutter test test/accessibility/text_size_audit.dart --name 'history mini' --dart-define=A11Y_OUTPUT=build/text_size_audit_history
```

## Matrix and coverage

64 cases: eight scenarios × two viewports × four scales. Each case can include
many screen states and scroll positions.

- `compact`: 320 × 568 logical pixels, 20-pixel top inset.
- `mini`: 375 × 812 logical pixels, 50-pixel top / 34-pixel bottom insets.
- Linear `TextScaler` factors: **1, 1.5, 2, 3**. These are stress levels, not
  exact mappings to iOS Dynamic Type categories. Insets are representative.
- Actual Inter and Material Icons fonts, English, light theme, iOS platform.
- Synthetic profiles, records, questions, and provider overrides; no backend
  connections or persistence. The fixed Rive logo is represented by a static
  text placeholder in a shell matching PageWrap's header geometry.

| Scenario | Exercised states |
| --- | --- |
| History | Initial list, filter sheet, active filter chip, expanded bowel-movement details, floating date row, calendar sheet |
| Record menu | Check-in carousel and category buttons, through the end of the list |
| Record flow | Actual RecordSplitter: Bristol, pain, choice, multi-choice, checkbox, free text, submit/review, leave confirmation |
| Redesigned record flow | Same path with `usesMultiSessionFlow` enabled |
| Study instructions | Actual PreStudyInfo content, acknowledgment and start controls |
| Account | Account heading, profile/baseline/record-flow links, account actions, reading preferences sheet |
| Detail fields, automatic | Long questions, numeric answers, stool/pain/choice/multi-select responses, notes, transit details |
| Detail fields, always stacked | Same content with the saved full-width layout preference |

Recording, Record menu, Study, and Account scroll through overlapping viewports.
History uses explicit positions to exercise sticky and floating states. If fixed
controls leave less than two body-text lines for a scroll view, the report flags
the constrained viewport and samples its middle/end instead of taking hundreds
of nearly identical slivers. A zero-height viewport cannot be swept.

## What the findings mean

- **Error / overflow:** Flutter reported a layout overflow, with its source
  location and full diagnostic context. These fail strict mode.
- **Review / truncated text:** a visible RenderParagraph exceeded its line
  limit. Some previews intentionally truncate; decide whether the missing text
  is essential before treating it as a defect.
- **Review / shrunken text:** a FittedBox painted text smaller than requested.
  This can hide scaling problems without reporting an overflow.
- **Review / constrained scroll viewport:** fixed controls consumed most or all
  of the space for the screen's readable content.

Review signals do not fail strict mode. Screenshots also catch issues the
detector does not: sibling overlap, partial clipping by ancestors, control
occlusion, custom-painted text, and awkward spacing. Visibility checks are
heuristic; obscured paragraphs behind a modal can produce review signals.

This is not an end-to-end accessibility certification. It does not cover all
study stages, onboarding, profile editors, graph/insight states, keyboard-open
forms, dark mode, translations, VoiceOver, touch targets, or real platform
nonlinear scaling. Record pages are navigated with their real page controller
and prefilled responses; no save is sent to a repository. The Study fixture
does not attach an active protocol, so its optional study-name switcher is absent.
Relative dates/time-remaining labels still use the current clock; these captures
are diagnostic artifacts, not pixel-perfect goldens.

## Fixing issues in batches

Start with [FINDINGS.md](FINDINGS.md), then:

1. Reproduce a finding with a focused screen/device filter. Check 1× beside the
   first failing scale and inspect the named widget's constraints.
2. Fix the shared layout rule: growing height, wrapping, stacking, or moving
   fixed content into the scrollable area. Preserve normal-size styling.
3. Add a focused regression test for the behavior that matters (text visible,
   button reachable, scroll position stable), using this audit's fixtures if
   useful. Keep these normal tests strict; do not collect/ignore their errors.
4. Run the affected audit case in strict mode and inspect review signals. Run
   the full matrix after changes to shared components.
5. Confirm on a small iOS simulator at the actual maximum text preference,
   including changing that preference while the screen is already open.

The opt-in entry point deliberately has no `_test.dart` suffix, so known app
issues do not make the ordinary test suite red. The detector's own regression
tests in `audit_harness_test.dart` do run in the ordinary suite.

To extend coverage, add a scenario in `text_size_audit.dart`, provider data in
`audit_fixtures.dart`, and named checkpoints around interactions. Keep assertions
that prove the intended screen/state loaded; a spinner is not a successful audit.

## Detail layout implementation

Account → Reading preferences now offers **Automatic** and **Question above
answer**. The choice is saved on this device for all profiles. The reusable
`StackedDetailField` and `InlineDetailField` are selected by `DetailField`.
Free text and multiple selections always stack; custom question renderers can
use these same components.

Automatic uses measured text with the current TextScaler and actual available
width. It stacks when the available width is less than 18 scaled body-font
units, or when either column would need more than two lines (one line in
viewports shorter than 480 logical pixels). These are initial layout policy
values, not platform accessibility categories. User-selected stacked mode takes
precedence. Built-in pain, stool, mood, and blue-dye detail rows share this policy.

Both detail-gallery scenarios are strict even in discovery mode: any recorded
error or text review signal fails them. Ordinary regression tests also check
live resizing/text changes, preference persistence, full-width grouping, and
short chips remaining on one line.
