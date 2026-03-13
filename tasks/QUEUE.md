# The Long Walk — Task Queue

## Active

_No active tasks. M5 complete. Planning M6._

## Backlog (M6 — not yet planned)

---

## How to use this file

- **PM/design agents**: Add new rows to Backlog, create a task file in `tasks/backlog/TASK-XXX.md`
- **Implementation agents**: Pick the top Backlog task, move its file to `tasks/in-progress/`, update status here
- **On completion**: Move file to `tasks/done/`, mark Done below, update the milestone file

## Done (M5 Into the Dark)

| ID       | Title                                              | Area        |
|----------|----------------------------------------------------|-------------|
| TASK-501 | Upgrade Pass (per-run economy)                     | progression |
| TASK-502 | Content Volume Pass (templates + enemies)          | data        |
| TASK-503 | Warden Phases 2+3 (+ save_version: 1)              | combat      |
| TASK-504 | Audio: Combat Readability Floor                    | audio       |
| TASK-505 | Pause Menu + RunScreen Ring Display                | ui          |
| TASK-506 | Bank on Death: Partial Loot Retention              | progression |
| TASK-507 | Per-Ring Contract Targets (Data-Driven)            | data        |
| TASK-508 | M5 Test Suite                                      | test        |

## Done (M4 The Road Opens)

| ID       | Title                                              | Area        |
|----------|----------------------------------------------------|-------------|
| TASK-401 | Ring selection UI + main.gd decoupling             | ui          |
| TASK-402 | Ring unlock gates + save migration                 | progression |
| TASK-403 | Enemy behavior profile dispatch                    | combat      |
| TASK-404 | Ring 3 encounter + boss spawn path fix             | combat      |
| TASK-405 | Warden boss encounter                              | combat      |
| TASK-406 | Win condition handler + credits screen             | ui          |
| TASK-407 | Heavy attacks + weapon stat reload fix             | combat      |
| TASK-408 | Loot threshold ring gate                           | progression |
| TASK-409 | M4 test suite                                      | test        |

## Done (M3 Combat Model)

| ID       | Title                                              | Area        |
|----------|----------------------------------------------------|-------------|
| TASK-301 | Player HP and death state                          | combat      |
| TASK-302 | Enemy damage output                                | combat      |
| TASK-303 | Weapon stat integration                            | combat      |
| TASK-304 | Guard damage reduction                             | combat      |
| TASK-305 | Dodge invulnerability frames                       | combat      |
| TASK-306 | Player poise tracking and stagger                  | combat      |
| TASK-307 | Combat HUD (HP, stamina, poise)                   | ui          |
| TASK-308 | Death screen and run summary                       | ui          |
| TASK-309 | Ring 1 combat balance pass                         | data        |
| TASK-310 | Full combat loop test suite                        | test        |
| TASK-311 | Fix: encounters_cleared never incremented          | combat      |
| TASK-312 | Fix: ridge_archer wrong ring_availability          | data        |
| TASK-313 | Fix: ash_flanker missing poise_damage              | data        |
| TASK-314 | Fix: poise_bar not initialized in _ready()         | ui          |

## Done (M2 Ring1 Slice)

| ID       | Title                                              | Area        |
|----------|----------------------------------------------------|-------------|
| TASK-201 | Sanctuary prep UI loadout selector                 | ui          |
| TASK-202 | Encounter templates data file and loader           | data        |
| TASK-203 | Save/load system for banked progression            | progression |
| TASK-204 | Combat arena scene and player movement controller  | combat      |
| TASK-205 | Enemy actor integration with state machine         | combat      |
| TASK-206 | Contract objective system v1                       | progression |
| TASK-207 | Verifier tests for save integrity and combat smoke | test        |
| TASK-208 | Telemetry event sink for run lifecycle             | infra       |
| TASK-209 | Enable Godot runtime execution in CI headless tests | infra      |

## Done (M1 Foundation)

| ID       | Title                                                  | Area  |
|----------|--------------------------------------------------------|-------|
| TASK-101 | Add queue labels and normalize default label set       | infra |
| TASK-102 | Add issue templates for task and milestone intake      | infra |
| TASK-103 | Add PR template with verifier section                  | infra |
| TASK-104 | Add CI workflows for required status checks            | infra |
| TASK-105 | Configure squash-only merge policy                     | infra |
| TASK-106 | Apply branch protection for main required checks       | infra |
| TASK-107 | Create Projects v2 board and status automations        | infra |
| TASK-108 | Seed M2 Ring1 slice backlog with atomic tasks          | infra |
