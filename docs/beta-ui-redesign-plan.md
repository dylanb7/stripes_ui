# Beta UI redesign sprint plan

Adopt the redesign's clearer navigation, resources, multi-category recording, timing controls, and category presentation behind `StripesConfig.betaUi`. Preserve the current question definitions and History experience. Start with the current dashboard and add clearer primary actions; decide whether to simplify its summaries after trying the recording flow.

This is a proposed implementation backlog. Task IDs below are local planning references, not external tracker issues. Application behavior has not been changed.

Source: [Stripes redesign report](</Users/dylanbaker/Desktop/Stripes_Report_July_2026_DEV Report_final.pdf>), 46 PDF pages. Page references use PDF page numbers. The report contains several design iterations and proposals beyond the requested scope; its annotations do not authorize questionnaire, authentication, or study-protocol changes.

## Product direction

The study involved seven caregivers completing Blue Meal Study tasks. It found difficulty locating the study, understanding progression, and recording multiple symptoms together (pages 2–5). These findings support improving those workflows. They do not establish that the proposed Home or History is better than the current implementation.

| Area | Proposed decision | PDF reference |
| --- | --- | --- |
| Navigation | Home, Record, History as distinct destinations; top-right menu opens a right drawer. | 6–7 |
| Menu | Keep account/profile access and existing account capabilities; add Resources and eligible blue dye state with a resume action. | 6–7, 11–12 |
| Blue dye visibility | Share existing state between menu and Home. Keep the active task visible on Home. | 13–14 |
| Resources | Add an app guide and reusable article view using existing approved explanations first. A CMS is a separate feature. | 15–17 |
| Recording | Select categories, choose timing, complete current questions, review, save. | 33–35, 42 |
| Question presentation | Adopt cards, selection states, progress, spacing, and category icons while preserving the current answer contract. | 36–44 |
| History | Keep the existing view, filters, graphs, and edit behavior. Add precision-aware labels where required by new records. | Proposed replacement on 28–32 is deferred. |
| Home | Put Record, Today's Entries, and any active study action above current summaries. Evaluate density after this change. | 13–14 |

Keep the current questionnaire IDs, wording, categories, answer choices, numeric ranges and increments, requiredness, and conditional branches. Do not introduce the PDF's fixed category list, meal types, expanded pain/GI/sleep questions, new study questions, or different exclusivity rules for answers merely to match a mockup.

Also defer onboarding/authentication changes, required name/DOB changes, consent lifecycle changes, study eligibility or completion-rule changes, a new support backend, new at-home study instructions, and grouped History editing. Resources may link to existing approved material without introducing a new protocol.

## Existing implementation and gaps

| Foundation | Current state | Planning implication |
| --- | --- | --- |
| Beta switches | [config.dart](../lib/config.dart) already separates dashboard, compact History, recording, category theme, graphing, and symptom editing. | Extend targeted switches; avoid enabling unrelated experiments together. |
| Navigation | [tab_view.dart](../lib/UI/Layout/tab_view.dart) uses the same tab for Record or Dashboard, and [route_provider.dart](../lib/Providers/Navigation/route_provider.dart) always supplies the profile button. | A separate Home and Record needs route/state work, not just a new label. |
| Help content | [home_screen.dart](../lib/UI/Layout/home_screen.dart) has a logo-opened `StripesInfoSheet`. | Reuse this content as a Resources starting point. |
| Study status | [action_items_section.dart](../lib/UI/History/DashboardView/action_items_section.dart) already shows resumable study tasks. | Reuse the existing providers rather than creating menu-owned study state. |
| Category themes | [category_theme.dart](../lib/Util/Design/category_theme.dart) maps stable category IDs to icons/colors and handles custom categories. | Extend the current mapping and keep labels alongside icons. |
| Recording | [record_session_provider.dart](../lib/Providers/Questions/record_session_provider.dart) models one path; [record_entry.dart](../lib/UI/Record/RecordSplit/record_entry.dart) submits one entry and forces exact time. | Multi-category and approximate-time UI remain implementation tasks. |
| Saving | [record_session_writer.dart](../lib/Providers/Record/record_session_writer.dart) accepts multiple entries with compensating rollback. | Reuse the boundary, but address failed rollback and retries before batch release. |
| Timing data | The sibling backend helper's `Entry` supports exact, morning, afternoon, evening, night, and not sure; legacy `DetailResponse` conversion drops precision. | Preserve precision through reads and edits; resolve the PDF's additional early-morning value explicitly. |

## Beta configuration

Proposed new switches are `menuNavigation`, `resources`, and `approximateTime`. Reuse `multiSessionFlow` and `useCategoryTheme`. `menuNavigation` owns the new Home/Record/History shell and drawer together, preventing partial navigation configurations. Enable Resources only where a visible entry point exists.

Approximate capture is active only when both `approximateTime` and `multiSessionFlow` are enabled. With `multiSessionFlow` off, an enabled `approximateTime` switch leaves the legacy capture UI unchanged. Readers must still retain precision in either configuration.

Preserve the existing History and graph settings during this rollout; do not repurpose `compactHistory`. Initially leave the existing `dashboard` behavior intact when the new navigation switch is off. Under the new shell, Home must always have content: the dashboard when selected, otherwise a minimal action view. Record must always remain independently reachable.

Use explicit beta overrides during rollout. `BetaUiConfig.enabled()` currently also enables History, graphing, and symptom editing. New constructor parameters should be optional, with beta-disabled defaults off; define and test the full-beta preset intentionally.

An approximate-time capture switch must not control the ability to read already-saved approximate entries. Turning off the new flow must preserve their meaning and must not silently rewrite them as exact. If a legacy editor cannot retain precision, route those entries through a compatible editor or prevent that incompatible edit.

## Sprint 1 Navigation and resources

### BUI01 Define the release switches and compatibility cases

Scope: add the targeted beta switches, define supported combinations, and identify the actual host configuration used to exercise them. Touchpoints: configuration, router, navigation tests, and question registry selection.

Acceptance:

- Beta disabled preserves current navigation and recording behavior.
- New navigation works with dashboard on or off and category styling on or off.
- History, graphing, symptom editing, and display settings retain their existing independent controls.
- Resources and study routes cannot become inaccessible through a flag combination.
- Preserve existing profile/study gates and host integration hooks.

Dependency: none. This is the first implementation task.

### BUI02 Add the menu and separate Home from Record

Scope: update the shared app shell, routes, and responsive navigation. Reuse profile/account screens and existing deep links. PDF pages 6–7 take precedence over older menu-tab illustrations for this proposed design.

Acceptance:

- Mobile navigation exposes Home, Record, and History; the top-right button opens a right drawer with a close control.
- Opening and dismissing the menu preserves the underlying destination and draft; opening it never selects a fourth bottom tab.
- Home and Record are separate routes/states; existing recording and test links continue to resolve.
- Profile, settings, exports, and sign-out remain available wherever existing configuration permits them.
- Browser/system Back, nested recording routes, desktop layout, keyboard focus, and large text behave coherently.

Dependency: BUI01.

### BUI03 Show blue dye status and the next action

Scope: reuse the current profile-scoped test/progress providers in a menu row and the Home action card. Adapt existing eligibility and lifecycle states; do not create enrollment fields from the report's suggested schema.

Acceptance:

- Eligible users can find/start or resume the appropriate existing flow from Home and the menu.
- Active, waiting, ready-to-continue, completed, unavailable, loading, and error cases render appropriately where those states exist.
- The menu and Home reflect the same current profile and protocol; another protocol cannot be mistaken for blue dye.
- Switching profiles updates state without exposing the previous profile's progress.
- Existing recorded study data remains accessible after completion. Protocol timing and completion rules remain unchanged.

Dependency: BUI02. Deeper study-screen restyling can follow independently.

### BUI04 Add the Resources index and article view

Scope: app overview, how to record/review entries, existing blue dye explanation, existing stool-scale reference where available, and existing support/legal links. Reuse localized About content. Provide expandable sections for longer material.

Acceptance:

- Resources is reachable from the menu and returns users to their prior destination.
- Core app guidance is bundled and available offline; external links are clearly identified.
- Multiple sections can remain expanded; content works with large text and screen readers.
- Study-specific resources follow existing eligibility rules, while general app guidance remains available to everyone.
- No new CMS, consent text, medical/protocol instructions, or support service is required to ship the initial index.

Dependency: BUI02 for navigation. Content work can run alongside BUI03 and the recording data contract.

## Sprint 2 Recording workflow and timing

This is the largest work package. Land and review its tasks separately; exact-time multi-category recording can ship before approximate capture if BUI05–BUI08 are complete and the approximate-time switch stays off.

### BUI05 Establish batch identity and time preservation

Scope: define the recording draft, persistence metadata, and compatibility path before wiring the new screens. Inspect required changes in `stripes_backend_helper` as a coordinated dependency.

Acceptance:

- A recording batch and a blue dye protocol run have distinct meanings and preserved relationships. A batch save/undo cannot overwrite or remove an entire study run.
- Bind a draft to its originating profile and question definitions; profile changes cannot redirect its save to another person.
- Retain occurrence date, timing precision, category-specific timing, and creation time through save, reload, and edit.
- Specify shared-date behavior, local day boundaries, UTC conversion, and future-date validation.
- Resolve day-part values: the PDF includes early morning, which the current enum lacks. Either add compatible storage support or deliberately retain existing supported windows; do not silently reinterpret values.
- Preserve null precision on old data as legacy exact time, consistent with the existing model.

Dependency: BUI01. Backend/model decisions are prerequisites for BUI08–BUI10.

### BUI06 Build category selection and the recording draft

Scope: multi-select currently available event categories, then maintain an independent existing question graph for each selected category. Include a shared occurrence date and exact-time input for the initial release. Keep baselines, periodic check-ins, and study steps on their existing specialized paths initially.

Acceptance:

- One or several categories can be selected; Continue requires at least one.
- Use category IDs from current configuration, including custom categories; do not hardcode the PDF's five categories.
- Answers survive Back, review/edit navigation, and movement between selected categories.
- Removing an answered category or leaving the flow follows a clear discard policy.
- Existing baseline gates, conditional questions, and study-injected questions continue to apply.
- The draft has predictable progress and does not reset when the menu briefly opens.
- The initial timing step supplies one shared date and exact time to all selected categories; BUI09 extends it with day shortcuts, separate timing, and approximate precision.

Dependency: BUI05.

### BUI07 Apply the new form presentation without changing answers

Scope: category icon headers, consistent cards/selection states, progress, and readable layouts around existing runtime questions. Reuse the category theme and question registry.

Acceptance:

- Question IDs, prompts, options, value ranges/increments, requiredness, and branching match the current definitions.
- Fix the existing beta numeric renderer's seven-integer-value cap and rounding behavior before broadly enabling it. A 0–10 or fractional question must retain its full valid domain.
- Existing specialized controls, including pain and stool-scale inputs, retain their intended behavior.
- Production continues to load its current questions; demo questionnaire content stays isolated.
- Icons and colors are consistent across selection, entry, and review, with readable text labels and custom-category fallback.

Dependency: BUI01; presentation work can proceed alongside BUI05–BUI06.

### BUI08 Add combined review and reliable save

Scope: one review card per category with edit links, visible date/time, and one save operation through the existing writer boundary.

Acceptance:

- Review shows exactly what will be saved and allows editing category answers and timing without losing other answers.
- Each selected category produces its intended record under the same recording batch; separate sessions never merge solely because their timestamps match.
- The app reports success only when the intended records have persisted, including existing blue dye associations/processing.
- Partial failure, failed compensation, and retry are explicit and duplicate-safe. Preserve the draft until the outcome is known.
- If study processing fails after records persist, recovery neither recreates those records nor advances the study twice.
- Undo targets the entries created by this batch; edits preserve identity and unrelated metadata.
- Saved entries appear in the current History independently. Grouped cards and group editing remain deferred.

Dependency: BUI05–BUI07. Test repository failures, not only successful multi-entry writes.

### BUI09 Add shared and per-category time controls

Scope: Today/Yesterday/Earlier, a shared date, default shared timing, and optional separate timing per category. Each timing card supports exact time, a supported day part, or not sure.

Acceptance:

- A single batch can mix an exact pain time, an approximate bowel-movement time, and unknown GI timing.
- Not sure still requires an occurrence date and never asks users to invent a clock time.
- Switching shared/per-category modes has a defined policy for preserving or replacing existing selections; no silent loss of edits.
- Validate each timing card and point users to missing/invalid input.
- Review and edit retain precision, including across midnight and daylight-saving changes.
- Study events requiring exact timing continue to follow current requirements. Approximate entries cannot silently drive exact transit calculations.

Dependency: BUI05–BUI08. Do not release capture until BUI10 is complete.

### BUI10 Preserve time meaning in existing readers

Scope: Entry/legacy response adapters, History labels, dashboard cards, filters, exports, charts, and any time-dependent insights/study calculations. Preserve the current History layout.

Acceptance:

- Approximate/unknown entries render as such; no fabricated exact clock time is presented as observed.
- Date grouping and sorting remain deterministic without implying an exact order for unknown times.
- Export retains date and precision with clearly documented compatible fields.
- Time-of-day graphs and interval calculations either represent uncertainty or explicitly exclude unsupported imprecise entries. Daily counts still include them.
- Reloading, editing, and disabling beta do not erase precision or detach study relationships.

Dependency: BUI05 and the timing draft contract. This can be developed alongside BUI09.

## Sprint 3 Home refinement and release checks

### BUI11 Make Home actions clear and evaluate dashboard density

Scope: retain the current dashboard's useful data while making Record, Today's Entries, and active study progress immediately visible. The existing Today chips switch from recording to expanding history once entries exist; the dedicated Record action should have a stable meaning.

Acceptance:

- Record always opens the same recording entry point; Today's Entries opens current History focused on today with a defined filter policy.
- Active profile and study next action are clear before scrolling through summaries.
- Existing recent entries and summaries remain available without crowding the primary actions.
- Compare a populated and empty dashboard against a simple quick-links variant using representative tasks: start a record, find today's entry, resume the study.
- Choose density based on task clarity and user feedback; a pure quick-links Home is optional and does not block the other sprints.

Dependency: BUI02–BUI03; final evaluation benefits from BUI06–BUI10.

### BUI12 Verify the supported release combinations

Scope: targeted widget/provider/integration checks plus a short manual walkthrough. Extend existing navigation, recording, writer, History, and accessibility tests.

Acceptance:

- Exercise beta disabled, navigation/resources only, category styling only, multi-category with exact time, and the complete supported recording configuration.
- Cover empty/populated History, custom categories, multiple profiles, active/inactive study states, and legacy entries.
- Verify cancellation, profile changes, duplicate submission, failed second write, rollback failure, retry, and batch-only undo.
- Verify approximate save/reopen/edit/export and beta rollback preserve meaning.
- Check small/mobile and desktop widths, keyboard/screen-reader navigation, large text, and existing localized strings.
- Run relevant Flutter tests and analysis for implementation changes; distinguish pre-existing failures from regressions.

Dependency: the tasks selected for the release. Each earlier task still carries its own focused validation.

## Decisions to settle during implementation

1. **Home density:** use the hybrid dashboard as the starting point; comparison can happen late.
2. **Day-part vocabulary:** confirm boundaries and whether early morning warrants a backend addition before BUI09.
3. **Study timing:** identify which existing study paths require exact time before exposing approximate choices there.
4. **Resources content:** use existing app/study text first; expanded educational content can be supplied separately.
5. **Batch persistence:** choose how to represent recording-batch identity independently from protocol identity, and how each supported repository handles partial failure.

Suggested implementation order: BUI01, then navigation/resources and the BUI05 data work in parallel; complete the recording tasks; finish Home evaluation and release validation. Changes to the questionnaire or study protocol require their own future scope.
