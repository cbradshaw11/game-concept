# M29 — Settings Screen: Audio, Display, and Controls

**Status:** COMPLETE
**Date Authored:** 2026-03-26
**Date Completed:** 2026-03-26
**Author:** Claude Code
**Scope:** SettingsManager autoload, settings screen modal with audio sliders, fullscreen toggle, controls reference, accessible from title screen and sanctuary

---

## Overview

M29 adds a proper settings screen to The Long Walk. The SettingsManager autoload persists master/SFX/music volume (dB) and fullscreen mode to `user://settings.json`, loading and applying saved values on game start. The settings screen is a modal overlay (CanvasLayer z=20) with three sections: audio sliders that update buses live, a fullscreen toggle, and a static controls reference. Accessible from both the title screen (new "Settings" button) and the sanctuary prep screen. "Save & Close" persists all changes; "Reset to Defaults" restores factory values.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | SettingsManager autoload — master/sfx/music volume dB, fullscreen bool, save/load/apply/reset | DONE |
| T2 | Settings screen scene + controller — audio sliders (-40 to 0 dB), fullscreen checkbox, controls reference, Save & Close / Reset buttons | DONE |
| T3 | Wire Settings button into title screen and sanctuary prep screen | DONE |
| T4 | Apply saved settings on load — SettingsManager._ready() calls load_settings() + apply_all() | DONE |
| T5 | Self-review pass — verified slider→bus→SettingsManager pipeline, reset rebuild, modal overlay | DONE |
| T6 | Test suite — 3 files, 20 assertions (settings_manager_test, settings_screen_test, audio_settings_test) | DONE |
| T7 | Milestone summary | DONE |

---

## Settings Fields

| Field | Type | Default | Stored In |
|-------|------|---------|-----------|
| master_volume_db | float | 0.0 | user://settings.json |
| sfx_volume_db | float | 0.0 | user://settings.json |
| music_volume_db | float | -6.0 | user://settings.json |
| fullscreen | bool | false | user://settings.json |

---

## Navigation

| Entry Point | Button Text | Behavior |
|-------------|-------------|----------|
| Title Screen | "Settings" | Opens modal overlay, title screen stays behind |
| Sanctuary (Prep Screen) | "Settings" | Opens modal overlay, prep screen stays behind |

---

## Deferred to M+1

- Control remapping (noted in UI: "Control remapping coming in a future update")
- Accessibility options (colorblind modes, text size)
- Resolution/window size presets
- Mute toggles per bus
