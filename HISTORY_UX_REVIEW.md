# STRiPES History UX and Accessibility Review

Reviewed: October 14, 2026

This review is based on the supplied mobile and tablet screenshots and the history implementation inspected on that date. Code observations are distinguished from accessibility behavior that still requires device testing. Source links refer to the implementation as reviewed and may change as development continues.

## Follow-up direction from the user

The following priorities and clarifications were provided after the review. They take precedence over conflicting assumptions in the original recommendations.

- **Implement resulting UI changes behind beta UI.** Implementation of empty states, entry previews, the period summary, the content-level view switch, and export placement is now authorized. These changes use the independent `BetaUiConfig.historyOverview` switch, off in the disabled preset and on in the enabled preset.
- **Prioritize the period summary.** Replacing the current entry-count-and-export row with a meaningful summary is an especially important change. For this iteration, export moves beside the content-level presentation controls.
- **Define the collection before choosing its presentation.** The user confirmed the hierarchy: **User/profile → Date + Filters (available entries) → Presentation**. Move the Entries/Patterns switch into the content area, after the date/filter controls and compact summary. Switching presentation preserves the selected profile, dates, and filters. The summary describes the same collection in either view; it is part of History, not a separate Overview destination.
- **Prioritize entry previews while preserving time orientation.** The latest requested order supersedes the earlier time-first subtitle proposal: **category → entry previews → timestamp**. Preview text animates out on expansion, while the category and timestamp remain. Honor reduced motion, and show only recorded prompt/response details.
- **Improve empty states.** Offer a link to the entry closest to the selected period, rather than limiting recovery to the latest entry overall. Preserve active filters; measure distance from the period boundaries, prefer the earlier entry when distances tie, and use a stable record ID to resolve remaining ties.
- **Reassess existing filter chips before adding them.** The user has prototyped filter chips and believes they may already be in the live app. Their vertical space cost is a concern. Verify the current implementation and explore a compact presentation rather than assuming chips are missing.
- **Advanced filters are intentionally disabled pending validation.** Time-of-day filtering and note search already have implementations; the live build disables them because they have not been validated. This is a validation and rollout question, not simply a missing-feature implementation task.
- **Defer graphing behavior to a separate discussion.** Placement of the view switch in the content area is agreed. Preserve the graphing review below as context; its chart and analysis recommendations are not an agreed implementation specification.

Implementation decisions for this iteration:

- Place a labeled **Export** action beside the content-level List/Graph controls. Wrap controls at larger text sizes. Export continues to use the selected, filtered top-level entries and the existing export options.
- Open the closest available entry directly in a scrollable detail sheet, retaining the original date/filter context. Provide an explicit **View this day** action, or **View this period** for a period-based review, for users who want to navigate there. This avoids requiring a search through a dense day's lazy-loaded list.
- Request the supported history range before offering a nearest-entry result. The repository interface does not certify remote completeness, so describe the **closest available entry**, including when offline.
- Keep the existing List/Graph names and chart behavior for now. Do not expose the unvalidated advanced filters as part of this iteration.

Implementation verification for this iteration: 121 History widget/provider and timing/filter regression tests pass. Rendered checks cover normal phone/tablet layouts and 320px screens at 3× text, including export and closest-entry details. Preview tests cover ordering, expansion, reduced motion, and semantics; recovery tests cover filter preservation, review periods, approximate dates, and edited/deleted entries. Broad analysis reports existing warnings/information in the surrounding History code, with no new diagnostics from these features. Device screen-reader and one-handed interaction testing remain to be done.

## Recommendation

Keep one History destination with two clearly visible views: **Entries** and **Patterns**. Establish the profile, dates, and filters first, introduce the available collection with a compact factual summary, then offer the presentation switch in the content area. Both views retain the same scope. Make moving between a pattern and its underlying entries effortless.

The current approach has a good foundation. Shared filters, sticky day headings, expandable entries, and the returning date navigator all support useful behaviors. The biggest opportunity is helping users understand **what they recorded before they start opening cards or configuring graphs**.

## Choosing the history modality

The two views serve different purposes, and that distinction is valuable. Users are likely coming to History with three questions:

- “What have I been recording?”
- “Is there anything interesting across my records?”
- “Where is that particular entry?”

The first needs an overview, the second needs aggregation, and the third needs recognizable entries and retrieval tools.

| Approach | Where it helps | Main tradeoff for STRiPES |
| --- | --- | --- |
| Current list/graph split | Supports individual records and analysis separately | Switching views currently changes presentation more effectively than it connects the two tasks |
| Continuous timeline with jump-to-date | Browsing backward, irregular logging, following events across date boundaries | Long histories become difficult to navigate; the period represented by graphs and exports needs separate definition |
| Everything in one feed | A small chart and its few related entries can work well together | A growing collection of charts pushes entry retrieval farther down the screen |
| **Period overview + Entries/Patterns** | Supports orientation, retrieval, and deeper exploration | Requires careful state preservation and direct links between views |

Evolve the existing model before replacing it with infinite scrolling. A continuous timeline would become more compelling if testing shows people repeatedly crossing period boundaries or paging through empty weeks to find their last record.

## Make the first screen meaningful

In the first phone screenshot, the first entry starts roughly halfway down the screen. The brand header, history title, control row, date selector, and entry count consume considerable space before users encounter their own information.

Use the agreed scope-before-presentation hierarchy:

1. Compact History heading with clear profile identity.
2. Compact date and filter controls defining the available entries.
3. A short summary of those records.
4. Visible **Entries | Patterns** selector within the content area.
5. The entries or pattern summaries.

A visible two-option selector makes the alternative discoverable and saves a tap compared with the current dropdown. Its placement communicates that the user is choosing how to explore the already selected collection. Switching views must preserve the date/filter scope and keep the shared summary consistent. Preserve readable labels when text grows. Final view naming remains open for the graphing discussion.

The summary should be small; Home already provides an overview surface. For example:

> **8 entries across 3 days**  
> Pain · Sleep & Mood · Meals

That gives the collection shape without creating another dashboard users must scroll past.

## Make sparse history specific and useful

Three records can contain substantial information if the screen shows what those records say.

For a hypothetical sparse history:

> **3 entries across 2 days**  
> Two pain entries and one sleep entry.

Below that, show recognizable recorded details. The user can immediately see that their effort produced a usable record.

Adapt the presentation to the available evidence:

- With a few observations, emphasize exact values, dates, and notes.
- With repeated observations, introduce distributions and changes over time.
- Show a relationship or trend only when the relevant measure has enough suitable evidence.

The number of entries alone is insufficient: twenty entries on one day provide different evidence from twenty entries spread across several weeks. The existing insight engine already provides useful measurement semantics and evidence thresholds to build on.

## Improve entry previews

Entry previews are probably the highest-value improvement to the list. In the screenshots, several “Sleep & Mood” entries differ only by time. Someone remembering a poor night's sleep has to open multiple cards to identify the right one.

The original review proposed examples such as:

> **Pain · 6/10**  
> Lower abdomen · 7:25 AM

> **Sleep & Mood**  
> 5 hours sleep · “Woke several times” · Tuesday

**Latest implementation refinement:** place the preview between category and time, and animate it away on expansion:

> **Pain**  
> Intensity: 6/10 · Location: Lower abdomen  
> 7:25 AM

> **Sleep & Mood**  
> Sleep: 5 hours · “Woke several times”  
> 11:59 PM

These are hypothetical examples, not a final field mapping. Use only values that were actually recorded. Show useful prompt/response information before the time, choosing one or two distinguishing details per entry type. Preserve full answers in the expanded content, and allow preview text to wrap at larger sizes.

This improves perceived substance, scanning, and accessibility simultaneously. Users spend fewer taps opening entries simply to discover whether they are relevant. Keep the whole row tappable and preserve expansion and position when they return—the implementation already has useful support for that.

## Preserve the user's train of thought during date navigation

Two concrete behaviors are worth changing early:

- History initially selects **today**, which can produce an empty history despite older records.
- Changing Day/Week/Month currently defaults its anchor to **now**. Someone inspecting September can select Week and unexpectedly return to October.

These behaviors originate in the [history settings provider](lib/Providers/History/display_data_provider.dart), around lines 294–315 in the reviewed version.

The initial design hypothesis is **Last 30 days on first use**, then remember the user's chosen view and range. Test that default with actual logging frequency.

When changing period size, retain the date being explored. Make “Today” or “Latest” an explicit action.

Empty states need different recovery paths:

| Situation | Useful response |
| --- | --- |
| No entries yet | Explain what will appear here and offer logging |
| No entries in this period | Offer the entry closest to the selected period, with its date clearly stated |
| Filters match nothing | Explain the active restrictions and offer to clear or broaden them |

The original review suggested a link to the latest entry for an empty period. The user's follow-up improves this to the **closest entry to that period**. This should help someone exploring older history without sending them back to the present. The implemented recovery respects active filters and opens details without changing scope; navigation to that entry's day or review period is a separate explicit action.

Never silently widen an explicitly selected period. Users need to trust that the label describes the records shown.

## Extend the returning date control's convenience

Keep the returning date control. It anticipates a real moment: someone deep in history decides they want to go somewhere else. Bringing navigation to their thumb is useful.

The implementation already handles reduced motion and reserves bottom clearance. However, the returning control contains only date navigation; filters and view switching remain at the top.

Prototype a compact lower control area once the original controls leave the screen:

- A reachable date/context control.
- A labeled **Refine** action opening search and filters, subject to validation and beta availability.
- Expansion into previous/date/next navigation when the user scrolls upward.

That preserves the delightful reveal while providing a stable way to reach controls. Keep it visible while someone is interacting with it or it contains accessibility focus. Test whether a little scroll-direction tolerance prevents flickering.

The navigation bar, date dock, and sticky heading must also leave enough room to read an entry at maximum text size. Bottom placement is helpful only if the remaining content stays usable.

## Improve retrieval and keep filter context compact

Finding an entry needs more than category filtering. In the reviewed code, the exposed filter choices include Category and Group; description, time, and numeric filtering have underlying implementations but are not exposed through the current selector. See [filter options](lib/UI/History/Filters/filter_logic.dart), around line 57 in the reviewed version.

The user clarified that advanced filtering is intentionally disabled in the live build pending validation. Existing filter chips have also been prototyped and may already be live, but their space cost is a concern.

The original retrieval priorities remain useful, with that implementation context:

- Validate search within notes and recognizable recorded text.
- Make active restrictions understandable and removable in a compact presentation.
- Support jump-to-date with visible recording activity.
- Offer a clear “Search all history” expansion when the selected period has no matches.

A badge showing “1” tells users that something is restricted, but cannot explain what. A label such as **Sleep & Mood ×** makes the current scope understandable. Assess how to retain that clarity without adding a large, permanently expanded chip area.

Keep date/category filters shared across Entries and Patterns. If text search also carries across, label that subset explicitly: **“Patterns from 5 matching entries.”** Searching for “after dinner” finds entries containing that phrase; the resulting chart must not appear to describe every dinner or every symptom.

## Graphing review — retained for later discussion

### Distinguish recording activity from recorded values

This is the most important interpretation issue in the screenshots.

“Average BM type (1–7)” shows a chart reaching **2**, while the selected detail shows **5.5 average**. The chart is counting recorded answers, while the title names the underlying measure. The implementation confirms that report counts and averages are separate calculations, with counts as the initial measure. See [graph preparation](lib/UI/History/GraphView/graph_preparer.dart), around line 129 in the reviewed version.

Both quantities can be useful, but the title, axis, and headline should describe the same quantity.

Proposed changes for discussion:

1. **Choose the default representation per measure.** Numeric observations, ordered categories, yes/no answers, and meal types need different presentations. An arithmetic average should require appropriate measurement semantics.
2. **Move technical form labels out of the overview.** “Multiple choice,” “Selectable,” and “Scale” occupy valuable space without explaining what happened.
3. **Use short, meaningful measure names.** “Did this bowel movement contain …” truncates precisely the information needed to identify the question. A concise name can link to the full original wording.
4. **Default comparisons to separate charts aligned by date.** Stacking meal answers and bowel-movement answers produces a total with little obvious meaning. Matching numeric bounds also do not establish matching units.
5. **Distinguish future dates from elapsed dates without records.** For the current month, use month-to-date or visibly mark the future region and Today. The empty second half of October currently dominates some previews.

Each pattern card should communicate a plain-language fact alongside its evidence count, with the chart supporting that message. Apple's [chart guidance](https://developer.apple.com/design/human-interface-guidelines/charts) similarly emphasizes descriptive summaries and clear context.

### Connect every chart to its underlying records

This would make the two-view architecture feel connected. For example:

**Pain summary → select Tuesday → View 3 entries → open an entry → return to the same chart selection.**

The graph data already retains its source responses, but the selected-data panel currently displays summaries without an entry-opening action. See [graph detail and data panel](lib/UI/History/GraphView/graph_view_screen.dart), around line 988 in the reviewed version.

Add that bridge, and preserve the original chart, filters, selection, and scroll position. Opening the supporting entries can be a temporary drill-down rather than replacing the user's main History settings.

This also gives sparse users a naturally unified experience: a small summary with its few supporting entries, inside the broader two-view structure.

## Accessibility priorities

Accessibility should preserve meaning and equivalent actions throughout these flows. There is already substantive work here: entry expansion semantics, generous entry targets, scaled layouts, chart labels, and reduced-motion handling.

The next priorities are:

- **Keep visible labels at large text sizes.** The current toolbar can replace Month and List/Graph with icons when space runs out. Semantic labels survive, but sighted users who enlarged the text lose visible context. Stack or reorganize labeled controls.
- **Make charts operable without precise touch.** Chart points have semantic labels, but selection is implemented through pointer interactions without equivalent activation actions on those points. Provide an accessible **View data** list, selectable observations, and the same source-entry links. See the [chart semantics implementation](lib/UI/History/GraphView/ChartRendering/history_chart_painter.dart), around line 323 in the reviewed version.
- **Provide navigable structure.** Dates should function as accessibility headings; entries should announce category, relevant preview, time, and expanded state in a sensible order. Hide the preview from semantics when expanded so it does not duplicate the full answer content.
- **Make calendar state understandable.** Announce the full date, selected state, and recording availability. Provide a date-entry alternative to navigating small calendar cells.
- **Protect focus from sticky controls.** The returning dock should neither cover the focused item nor disappear while it is being operated. This is a specific concern addressed by [W3C's focus-obscuring guidance](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html).
- **Measure contrast and provide non-color distinctions.** Check pale instructional text and yellow/lime chart marks. Use labels, shapes, or separate panels to distinguish series. Relevant benchmarks are [text contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) and [non-text contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).

For this Flutter app, target at least 48 logical pixels for routine controls and verify the complete experience with large text, VoiceOver, TalkBack, and keyboard/switch navigation. Flutter's [accessibility guidance](https://docs.flutter.dev/ui/accessibility) supports generous targets and actual assistive-technology testing. Screenshot review and overflow tests cannot establish that those interactions work.

## Moments of delight

Delight should come from recognition, continuity, and saved effort. The returning navigator fits that direction. Other worthwhile moments would be:

- Linking an empty period to the closest recorded entry and clearly showing where it is.
- Jumping to a date and briefly highlighting the destination entry.
- Returning from a graph or detail view exactly where the user left off.
- Showing recording activity in the date picker so users can choose a useful destination.
- Letting someone save an entry for an upcoming conversation or appointment, if that proves to be a common task.
- Quietly acknowledging that a small collection is useful: “Your three entries are saved here.”

These interactions can feel personal without requiring decorative animation. Reduced-motion users should receive the same orientation cues.

## Tablet layout

Test a chronological list beside a detail or pattern pane. The current two-column entry grid uses space efficiently, but makes time order less immediate to scan. A wider display can support simultaneous context and detail.

## Suggested sequence and validation

The original review proposed three stages. All implementation should follow the beta UI direction above, and graphing remains deferred pending discussion.

1. **Improve orientation and retrieval:** meaningful entry previews, explicit filter context, better defaults and empty states, preserved date anchors, and a visible Entries/Patterns selector. The user specifically prioritizes the summary, category/preview/time rows, and closest-entry empty states. Reassess existing chips and validate advanced filters before exposing them.
2. **Improve interpretation, after the graphing discussion:** measure-appropriate charts, clearer names and units, future/missing-data treatment, accessible data views, and chart-to-entry navigation.
3. **Test navigation alternatives:** compare the improved period model against a continuous journal using sparse, dense, and irregular histories.

The deciding tasks should be concrete:

- Find a remembered note without knowing its date.
- Inspect the records behind a chart value.
- Follow events across a month boundary.
- Open the closest entry from an empty selected period.
- Return after opening an entry without losing position or context.

Measure successful retrieval, unnecessary navigation, lost context, and whether users correctly understand the chart. Those results would tell us whether continuous history solves a remaining problem substantial enough to justify changing the model.
