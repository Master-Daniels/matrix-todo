# Improvements Spec — Usage, Visuals & Spacing

> STATUS: ALL WORKSTREAMS IMPLEMENTED + TESTER ROUND (see § Tester round).
> Source: review of all app screens (Today / Upcoming / Lists / ListDetail / Settings)
> + codebase in `lib/src/`. Design constraint: `design/DESIGN.md` architectural brutalism.
> Out of scope: duplicate dev test data, and `Schedule 2-min Test Alarm` dev button
> — dev will delete, not restyle.

## 0. Global constraints

- 1px solid borders, 0px radius everywhere, contiguous grid (`gutter/margin 0`).
- Megrim for headings/task titles, Space Mono uppercase for labels/indices/metadata.
- State via binary inversion (black fill / white text), not color.
- Spacing tokens only: `AppSpacing` in `lib/src/theme/app_spacing.dart:6-15`
  (`xs 4 / sm 8 / md 16 / lg 24 / xl 32`).
- No `BorderRadius.circular`, no `ElevatedButton` outside `lib/src/widgets/button.dart:9-65`,
  no alpha borders.

## WS1. Task-list spacing (requested fix)

Problem:

- `lib/src/widgets/task_cell.dart:67` uses `EdgeInsets.all(AppSpacing.md)` (16px).
- `lib/src/pages/settings/settings_sections/toggle_row.dart:32` and
  `segmented_row.dart:34` use `AppSpacing.lg` (24px) — hence Settings feels airier.
- `lib/src/pages/upcoming/upcoming_sections/timeline_section.dart:415-416`
  (`UpcomingTaskRow` body) also uses `md`, plus an extra header strip
  (`timeline_section.dart:355-414`) with its own border — denser still.
- `lib/src/pages/lists/lists_sections/core_list_card.dart:75-80` uses
  `margin md/sm`, which is why Lists feels spaced.

Fix (keep contiguous borders, do not card-ify):

1. `TaskCell`: `padding all(md) -> all(lg)`. Title gap `4 -> 8`
   (`task_cell.dart:123`), description gap `4 -> 8` (`task_cell.dart:137`).
2. `UpcomingTaskRow` body: `Padding(all md) -> all lg` (`timeline_section.dart:415-416`).
   Keep header strip at `horizontal md / vertical sm` to preserve two-tier hierarchy.
3. `ListDetailPage` header (`lib/src/pages/list_detail/list_detail_page.dart:55-86`):
   `padding all md -> all lg`, add `SectionHeader(title: '00 // Folder index', index: '[SEC 00]')`
   above it for rhythm parity with Settings.
4. Fix violation: `core_list_card.dart:137` `BorderRadius.circular(8) -> BorderRadius.zero`,
   border `withValues(alpha: 0.35) -> solid primary` (`core_list_card.dart:133-135`).

Accept:

- Settings and task rows share 24px body padding.
- Borders stay shared/contiguous, no rounded corners.
- Verify on Today / Upcoming / Detail in light + dark.

## WS2. Today (`lib/src/pages/home/home_page.dart`, `home_sections/home_metrics.dart`)

1. Filter pills (`home_metrics.dart:77-95`): add end spacer / fade so
   `HOME & LIVING (` no longer clips. Min tap height 44px.
2. Segmented meter (`home_metrics.dart:105-133`): completed segments
   `surfaceContainerHigh -> primary`. Show `%` next to `00 / 11 COMPLETED`
   (`home_metrics.dart:44-50`).
3. `HomeGuide` hint `SWIPE RIGHT = COMPLETE`: bump contrast to `primary`.
4. Deck strips `#02/#03`: `maxLines 2 -> 1` with ellipsis, time never wraps.

Accept: no clipped pills, meter readable at 0% and 100%.

## WS3. Upcoming consistency

1. Single time format via `fmtDueStamp()` (`upcoming_sections/upcoming_format.dart`).
   Remove `AM` vs `HRS` mix in `timeline_section.dart:403-411` and `task_cell.dart:113-119`.
   Standard: `07:30`, `14:00 HRS`, `ANYTIME`, overdue `DUE YESTERDAY 18:00`.
2. One focus signal: keep `[NOW // FOCUS]` inversion (`task_cell.dart:87`),
   demote `DayStrip` `NOW` chip to outline-only.
3. `ScheduleTerminal` (`upcoming_sections/schedule_terminal.dart:25-56`) already wires
   ICS via `schedule_export.dart:99-111` — keep, add health line
   `X DONE / Y TOTAL // Z OVERDUE` above buttons.

Accept: same task shows identical stamp on Today / Upcoming / Detail.

## WS4. Lists (`lib/src/pages/lists/lists_page.dart`, `lists_sections/core_list_card.dart`)

1. Wire dead search `CustomIconButton(icon: search)` (`lists_page.dart:33`) to new
   `SearchSheet` (see WS7). Same for Today search (`home_page.dart:27-29`).
2. `NEXT PRIORITY` box (`core_list_card.dart:128-137`): 0 radius, solid 1px border,
   `padding sm -> md`.
3. Empty custom lists: replace plain text (`lists_page.dart:86-97`) with dashed
   `[EMPTY]` box like `_DashedEmpty` (`timeline_section.dart:158-228`).

Accept: both search icons open working filter, no dead buttons.

## WS5. ListDetail toolbar

Add above `SectionHeader Tasks // Entries` (`list_detail_page.dart:87`):

- `[ALL | ACTIVE | DONE | HIGH]` segmented + sort `[TIME | PRIORITY | ADDED]` +
  `CLEAR COMPLETED` ghost button with confirm dialog.
- Local page state, default `ALL + TIME`. Reuse `SegmentedRow` styling, compact
  horizontal scroll.

Accept: filter/sort applies instantly, clear only removes `done == true` for that
`listId`, invalidates `listTasksProvider` + `listCountsProvider` + `listsSummaryProvider`.

## WS6. Settings polish (`lib/src/pages/settings/settings_page.dart:160-231`)

1. `CLOUD SYNC` row: relabel `LOCAL VAULT // NO CLOUD`, badge `STUB`, tap shows
   existing `ResultDialog`. Same for `IMPORT BACKUP`
   (`settings_sections/data_section.dart:83-94`).
2. Replace hardcoded `SYSTEM REVISION: 0.0.1` and footer `VERSION 0.0.1-BUILD-2026`
   (`settings_page.dart:51`, `232-254`) with `packageInfo.version + buildNumber`
   (`package_info_plus`, new dep) or `String.fromEnvironment`.

Accept: no fake `SYNC NOW` promise, version auto-updates.

## WS7. Search

New `SearchSheet` bottom sheet: text field + results from `tasksProvider`.
Called from Today, Upcoming (add missing icon), Lists.
Tap result opens `AddTaskSheet(task:)` or pushes `ListDetailPage`.

Accept: case-insensitive title/notes/category match, empty state.

## WS8. Subtasks (model exists, no UI)

Model: `lib/src/data/models.dart:143-177`, DB already has `getSubtasks()`.

1. `AddTaskSheet`: editable subtask list (add / check / delete).
2. `TaskCell` / `UpcomingTaskRow`: show `▢ 2/5 SUBTASKS` line when present, tap expands.
3. Toggle invalidates `tasksProvider` + `listTasksProvider`.

Accept: subtasks persist, progress counts.

## WS9. Undo on swipe-complete

After `HomeDeckSwipe onComplete` in `timeline_section.dart:489-502`,
`list_detail_page.dart:214-227`, `core_list_card.dart:225-236`:
show `SnackBar [TASK DONE // UNDO]` 4s. Undo calls `setTaskDone(id, false)` +
same invalidations + `reminderService.syncAll`.

Accept: undo restores + reschedules notification.

## WS10. Overdue surfacing

Reuse `_detailStamp()` + `isOverdueDay` (`list_detail_page.dart:122-129`) on Today deck
and ListDetail rows: red `DUE YESTERDAY 18:00` stamp, overdue header `[!!]`
non-inverted like Upcoming (`timeline_section.dart:73-80`).

Accept: overdue visible on all three surfaces, not just Upcoming.

## WS11. Notifications — make stubs real

`settings_providers.dart:49-56` `briefing`, `streakReminder` persist only today.
Wire like `_toggleReminders` (`settings_page.dart:261-277`):

- `briefing=true`: daily 08:00 summary via `reminderService`.
- `streakReminder=true`: evening check if `todayCountsProvider` has remainder.
- Toggle off cancels its IDs, toggle on calls `ensureReady() + syncAll()`.

Accept: survives restart, off cancels, on schedules.

## WS12. Import

Keep JSON+CSV export (`data_section.dart:152-207`) as-is.
Implement JSON import: pick file, parse `lists / tasks / subtasks / settings`,
insert via `AppDatabase`, invalidate root providers. Reuse double-confirm from purge
(`data_section.dart:209-244`).

Accept: export → purge → import roundtrips without loss.

## WS13. Recurrence + reorder

1. Add `recurrence` column (`NONE / DAILY / WEEKLY`) to `TodoTask` + `AddTaskSheet`
   dropdown. On complete, if recurring, clone next `dueDate`. Needs DB migration.
2. ListDetail drag handle to reorder updates `sort`, persists.

Accept: migration handles old DBs, reorder survives reload.

## WS14. Streak

Replace static `7-DAY STREAK` (`home_metrics.dart:57`) with computed provider:
consecutive days with `completed == total > 0`, else `0-DAY`. Show `■ STREAK N`.

Accept: 0 tasks = 0 streak, gap resets.

## Order + verification

1. WS1 + WS3 + WS4 + WS6 (visual).
2. WS5 + WS7 + WS9 + WS10.
3. WS8 + WS11 + WS12 + WS14 + WS13.
4. WS2 polish.

Verify: `flutter analyze`, `flutter test`, manual pass on
Today / Upcoming / Lists / Detail / Settings in light + dark, ICS save,
backup roundtrip.

## Tester round (Oct 2026) — all implemented

1. **Declutter**: Today pills → filter sheet, guide first-run only, streak →
   Stats screen (tap streak or Settings hub); Upcoming `THIS WEEK | LATER`
   segment; ICS export moved Upcoming terminal → Settings Data; Lists cards
   drop inline next-priority preview; ListDetail 8-segment toolbar → FILTER
   sheet button; Settings split into hub + Appearance / Notifications / Data
   sub-screens.
2. **Legibility**: Space Grotesk body (16/24, 15/22, 13/18), labels ≥11px,
   Megrim display-only, sentence case for titles/notes/descriptions,
   `DESIGN.md` updated. App-bar index uses 11px index-indicator to fit
   kToolbarHeight.
3. **On-time alarm**: `ReminderKind.atStart` (append-only, existing ids
   stable), `STARTING NOW` fire, MARK DONE + SNOOZE actions, copy updated.
4. **Extras**: 3-page first-run onboarding (`onboarding_seen`), `↻
   DAILY/WEEKLY` row tags, 5s titled undo snackbars (clone deleted on undo),
   empty-state actions (ListDetail locked-add, later-week plan), streak
   skips empty days, streak nudge stays 20:00.
