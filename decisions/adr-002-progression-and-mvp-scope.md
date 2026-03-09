# ADR-002: Progression Model and MVP Scope

Date: 2026-03-09
Status: Accepted

## Context
Two progression approaches were considered for The Long Walk:
1. Story-first with a finite main arc and post-game replay.
2. Replay-first with no explicit ending.

The project is intended to be built heavily with agents, so scope clarity and testability are top priorities.

## Decision
Adopt Story-first for MVP:
1. Build a finite 3-ring main arc with a clear ending.
2. Gate completion on successful extraction of the Artifact from Ring 3.
3. Unlock endless Frontier Mode after credits as post-game.

## Why
1. Stronger player motivation and pacing.
2. Cleaner acceptance criteria for an agent-driven workflow.
3. Lower risk of unfocused content expansion.
4. Post-game still preserves long-term replay value.

## MVP Scope Constraints
1. Rings
- Ring 0 Sanctuary
- Ring 1 Inner
- Ring 2 Mid
- Ring 3 Outer

2. Combat
- Player verbs: Attack, Dodge, Guard
- Weapons: Blade, Polearm, Bow

3. Content
- 6 enemy archetypes
- 1 outer-ring Warden boss
- 10 contracts
- Main story arc to credits

4. Systems excluded from MVP
- Multiplayer
- Player trading
- Large economy simulation
- Broad life-skill progression

## Consequences
1. Narrative implementation is required for launch quality.
2. End-to-end quest progression testing is mandatory.
3. Endless replay systems can be deferred without threatening MVP completion.

## Next Actions
1. Build first vertical slice: Sanctuary -> Ring 1 -> extract loop.
2. Implement deterministic seeded encounter generation.
3. Establish verification gates for combat, progression, and save/load.

