# M6: Surface Layer

**Status: DONE**
**Branch: TBD**

---

## Goal

Make the game presentable as a complete experience from first launch to credits. Add a title screen and main menu entry flow, a shop/vendor system in the sanctuary, a prologue/onboarding sequence, visual polish for the combat floor, and full UI audio coverage. A new player should be able to open the game, read what it is, buy their first upgrade, enter the rings, and die -- all without friction.

---

## Exit Criteria

- [x] Title screen: displays on launch; "New Game" and "Continue" route correctly; no double-title bug
- [x] Prologue: plays once on new game; does not replay on continue; state persists to save
- [x] Shop/vendor: accessible from sanctuary; items purchasable with loot; per-run apply works correctly; buy lock prevents double-spend
- [x] Settings menu: accessible from title and pause; display options save and reload correctly
- [x] Audio: UI sounds wired in flow_ui.gd; music tween on scene transition works without race condition
- [x] Visual: combat presentation floor assets in place; combat feedback (hit flash, screen shake) functional
- [x] Save: quit-save persists on exit; save path consistent across scenes
- [x] Test suite: 5 new M6 tests pass; zero M5 regressions

---

## Tasks

| ID       | Title                                              | Priority | Area        | Status  | Depends On     |
|----------|----------------------------------------------------|----------|-------------|---------|----------------|
| TASK-601 | Visual Assets: Combat Presentation Floor           | p2       | art         | done    | none           |
| TASK-602 | Combat Feedback Clarity Pass                       | p1       | combat      | done    | none           |
| TASK-603 | Prologue / Onboarding + Audio Files                | p1       | ui          | done    | none           |
| TASK-604 | Shop / Vendor System (Sanctuary)                   | p1       | progression | done    | none           |
| TASK-605 | Title Screen and Main Menu Entry Flow              | p1       | ui          | done    | none           |
| TASK-606 | Audio Polish: UI Sounds in flow_ui.gd              | p2       | audio       | done    | none           |
| TASK-607 | Settings Menu and Display Configuration            | p2       | ui          | done    | none           |
| TASK-608 | M6 Test Suite                                      | p1       | test        | done    | TASK-601..607  |

---

## Wave Dispatch Plan

```
Wave 1 (parallel -- no dependencies):
  TASK-601  Visual Assets: Combat Presentation Floor
  TASK-602  Combat Feedback Clarity Pass
  TASK-603  Prologue / Onboarding + Audio Files
  TASK-604  Shop / Vendor System (Sanctuary)
  TASK-605  Title Screen and Main Menu Entry Flow
  TASK-606  Audio Polish: UI Sounds in flow_ui.gd
  TASK-607  Settings Menu and Display Configuration

Wave 2 (all Wave 1 complete):
  TASK-608  M6 Test Suite
```

---

## Deferred to M7

- Run history screen (past runs, outcomes, rings reached)
- Victory screen and extraction summary on successful Warden kill
- XP-gated weapon unlock system
- Persistent upgrade display on sanctuary screen
- Encounter template variety expansion beyond 5 per ring
- Conditional upgrades (prerequisites, stat thresholds)
- Warden phase HUD indicator during combat
