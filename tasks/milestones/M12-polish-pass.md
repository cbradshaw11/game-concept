# M12: Polish Pass

**Status: DONE**
**Branch: TBD**

---

## Goal

Stabilize the experience by clearing all known M11 carryover bugs and making the game feel cohesive from a moment-to-moment play perspective. Tune Warden Phase 3 to be survivable rather than punishing, and introduce ring-differentiated combat music so each zone has its own sonic identity with a safe fallback for rings that lack a dedicated track.

---

## Exit Criteria

- [x] Carryover bugs resolved: total_runs display correct; story modal pause guard prevents input bleed; modal min-size constraint enforced; tutorial dismiss has no soft-lock path
- [x] Warden Phase 3: attack_cooldown tuned from 0.4 to 0.5; average survival window >= 4 seconds in Phase 3
- [x] Combat music: each ring references a music track key in rings.json; ring_director loads per-ring track or falls back to music_combat.wav without error
- [x] Music fade: no race condition on scene transition; fade-out completes before new track starts
- [x] Enemy state machine: no orphaned ATTACK state on enemy death; guard_counter does not crash on rapid input
- [x] Modal: no double-fire on story beat re-entry; overflow clipped correctly at all window sizes
- [x] run_number: no collision between concurrent or rapid sequential runs
- [x] Test suite: M12 tests cover music fallback, modal guard, and run_number uniqueness; zero M11 regressions

---

## Tasks

| ID        | Title                                              | Priority | Area        | Status  | Depends On      |
|-----------|----------------------------------------------------|----------|-------------|---------|-----------------|
| TASK-1201 | Fix M11 Carryover Bugs                             | p1       | bugfix      | done    | none            |
| TASK-1202 | Warden Phase 3 attack_cooldown Tuning              | p1       | balance     | done    | none            |
| TASK-1203 | Ring-Differentiated Combat Music Architecture      | p1       | audio       | done    | none            |
| TASK-1204 | M12 Test Suite                                     | p1       | test        | done    | TASK-1201..1203 |

---

## Wave Dispatch Plan

```
Wave 1 (parallel -- no dependencies):
  TASK-1201  Fix M11 Carryover Bugs
  TASK-1202  Warden Phase 3 attack_cooldown Tuning
  TASK-1203  Ring-Differentiated Combat Music Architecture

Wave 2 (all Wave 1 complete):
  TASK-1204  M12 Test Suite
```

---

## Deferred to M13

- Vendor per-run pool expansion beyond 3 items
- Upgrade pool expansion beyond 16 cards
- Death flavor text per ring
- solo warden_herald encounter template and sniper_volley behavior profile for void_sniper
- kite_volley dead zone documentation and push_warning for unknown behavior profiles
- Content depth pass: more variety in enemy compositions per template
