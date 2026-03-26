# M25 — Encounter Variety: Authored Encounter Templates

**Status:** COMPLETE
**Date Authored:** 2026-03-25
**Date Completed:** 2026-03-25
**Author:** Claude Code
**Scope:** 18 new authored encounter templates across 3 rings, weighted selection, encounter flavor text banners

---

## Overview

M25 replaces procedural noise encounters with authored templates that have distinct tactical identities. Each template defines a specific enemy composition with an evocative name and flavor text. Weighted selection ensures common formations appear more often while keeping rare compositions as surprises. A 2.5-second flavor text banner displays before each templated encounter, grounding the player in the Cauldron's world.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Audit existing 13 templates — schema, ring coverage, enemy ids | DONE |
| T2 | Add 18 new encounter templates (6 inner, 6 mid, 6 outer) with name, weight, flavor_text | DONE |
| T3 | Weighted template selection in RingDirector + flavor_text/template_name passthrough | DONE |
| T4 | Encounter flavor text display — 2.5s fade banner in FlowUI before combat starts | DONE |
| T5 | Self-review — fixed MAX_SAME_ENEMY_TYPE (2→3) for 3x grunt templates | DONE |
| T6 | Test suite (3 files, 21 assertions) | DONE |
| T7 | Milestone summary | DONE |

---

## Template Distribution

- **Inner Ring (10 total):** 4 existing + 6 new — Advance Party, Overwatch, The Charge, Wall and Volley, Ambush, Solo Flanker
- **Mid Ring (11 total):** 5 existing + 6 new — Ash Pack, Suppression Line, Berserker Escort, The Wall, Glass Volley, Full Pack
- **Outer Ring (10 total):** 4 existing + 6 new — Caster Guard, Hunter Pair, Flanked Approach, The Siege, Glass Cannon Run, Final Approach

## Key Changes

- `encounter_templates.json` — 31 templates total, all with name/weight/flavor_text fields
- `ring_director.gd` — `_weighted_pick()` for cumulative weight selection, flavor_text/template_name passthrough, MAX_SAME_ENEMY_TYPE bumped to 3
- `flow_ui.gd` — `show_encounter_flavor()` displays fade-in/out banner (0.3s in, 2.2s hold, 0.4s out)
- `main.gd` — wires encounter flavor_text to FlowUI before combat arena activation

---

## Deferred to M+1

- Formation positioning (enemies spawning in specific spatial arrangements per template)
- Template difficulty scaling based on encounters cleared in current run
- Template-specific music stingers or ambient changes
