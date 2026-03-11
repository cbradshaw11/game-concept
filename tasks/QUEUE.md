# The Long Walk — Task Queue

## Active

| ID       | Title                                        | Priority | Area   | Status  | Milestone      |
|----------|----------------------------------------------|----------|--------|---------|----------------|
| TASK-301 | Player HP and death state                    | p1       | combat | ready   | M3 Combat Model |
| TASK-303 | Weapon stat integration                      | p1       | combat | ready   | M3 Combat Model |

## Backlog

| ID       | Title                                        | Priority | Area   | Unblocked By  | Milestone      |
|----------|----------------------------------------------|----------|--------|---------------|----------------|
| TASK-302 | Enemy damage output                          | p1       | combat | TASK-301      | M3 Combat Model |
| TASK-307 | Combat HUD (HP, stamina, poise)              | p1       | ui     | TASK-301      | M3 Combat Model |
| TASK-304 | Guard damage reduction                       | p1       | combat | TASK-302      | M3 Combat Model |
| TASK-305 | Dodge invulnerability frames                 | p1       | combat | TASK-302      | M3 Combat Model |
| TASK-306 | Player poise tracking and stagger            | p2       | combat | TASK-302      | M3 Combat Model |
| TASK-308 | Death screen and run summary                 | p2       | ui     | TASK-302      | M3 Combat Model |
| TASK-309 | Ring 1 combat balance pass                   | p2       | data   | TASK-302,303  | M3 Combat Model |
| TASK-310 | Full combat loop test suite                  | p1       | test   | TASK-301-306  | M3 Combat Model |

---

## How to use this file

- **PM/design agents**: Add new rows to Backlog, create a task file in `tasks/backlog/TASK-XXX.md`
- **Implementation agents**: Pick the top Backlog task, move its file to `tasks/in-progress/`, update status here
- **On completion**: Move file to `tasks/done/`, mark Done below, update the milestone file

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
