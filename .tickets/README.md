# Local Ticket System

This directory is the source of truth for task delivery state.

## Structure

```
.tickets/
  open/       — tickets currently open (ready, in_progress, blocked, verifying)
  closed/     — tickets that reached done state
  events/     — JSONL audit event log per ticket
.plans/       — execution plan contracts per ticket
.memory/      — sprint closeout records and session checkpoints
```

## Ticket Lifecycle

```
ready -> in_progress -> verifying -> done
                     -> blocked -> in_progress
```

## Usage

Use the `/deliver-pb` skill to deliver a ticket:

```
/deliver-pb TASK-209
```

See `.agents/skills/deliver-pb/SKILL.md` for full protocol.

## Current State

- **Open:** TASK-209 (Enable Godot runtime execution in CI)
- **Closed (M1):** TASK-101 through TASK-108
- **Closed (M2):** TASK-201 through TASK-208
