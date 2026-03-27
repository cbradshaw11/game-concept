# M34: Save Version v10 + Control Remapping

**Status: DONE**
**Date Completed:** 2026-03-26

---

## Goal

Ship two deferred items from M33: formal save version bump to v10 covering all M27-M32 fields, and replace the placeholder controls section in settings with a live InputMap-driven reference grid.

---

## Exit Criteria

- [x] `SAVE_VERSION` const set to 10 in `save_system.gd`
- [x] Version history comment block documenting v7→v10 changes
- [x] `save_state()` injects `_save_version` field into save data
- [x] v10 migration guard comment in `load_state()`
- [x] v9 saves migrate cleanly (merge-with-defaults fills resonance, achievements, challenges)
- [x] Settings screen CONTROLS section reads bindings from InputMap at runtime
- [x] 6 core actions displayed: Move, Attack, Dodge, Guard, Interact, Pause
- [x] `interact` action added to project.godot InputMap (E/F keys)
- [x] Tests pass: `test_save_v10.gd`, `test_controls_display.gd`

---

## Tasks

| # | Task | File(s) | Status |
|---|------|---------|--------|
| 1 | Add SAVE_VERSION=10 const + version history comment | `save_system.gd` | Done |
| 2 | Inject `_save_version` into save data on write | `save_system.gd` | Done |
| 3 | Add v10 migration guard comment | `save_system.gd` | Done |
| 4 | Replace hardcoded controls with InputMap GridContainer | `settings_screen.gd` | Done |
| 5 | Add `_get_bindings_text()` helper reading from InputMap | `settings_screen.gd` | Done |
| 6 | Register `interact` action in project InputMap | `project.godot` | Done |
| 7 | Write save v10 migration test | `tests/m34/test_save_v10.gd` | Done |
| 8 | Write controls display test | `tests/m34/test_controls_display.gd` | Done |

---

## Deferred to M35

- Weapon variety expansion (3 new weapons)
