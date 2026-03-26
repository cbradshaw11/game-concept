# M27 — Meta-Progression: Resonance Shards and Permanent Unlocks

**Status:** COMPLETE
**Date Authored:** 2026-03-26
**Date Completed:** 2026-03-26
**Author:** Claude Code
**Scope:** Resonance Shards persistent currency, 12 permanent unlocks across 3 tiers, Resonance Shrine sanctuary UI, unlock application on run start, save version bump (v10)

---

## Overview

M27 adds meta-progression so every run feels meaningful regardless of outcome. Resonance Shards are a persistent currency earned at the end of every run (death or extraction). Shards can be spent at the Resonance Shrine in the sanctuary on permanent minor unlocks that persist between runs. The system ensures that even failed runs advance the player's overall power.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Add resonance_shards, resonance_spent, permanent_unlocks to GameState with save v10 migration | DONE |
| T2 | Create permanent_unlocks.json — 12 unlocks across 3 tiers (50/120/250 shards) | DONE |
| T3 | Resonance Shrine UI — sanctuary panel with tier-grouped unlocks, shard balance, purchase flow | DONE |
| T4 | Apply permanent unlocks on run start — stat bonuses, starting silver, contract reduction, modifier carry | DONE |
| T5 | Self-review — fixed artifact_echo tier filter bug, wired deep_pockets into RewardSystem | DONE |
| T6 | Test suite (3 files, 29 assertions) | DONE |
| T7 | Milestone summary | DONE |

---

## Shard Earning Formula

- Base: 10 shards per run (always)
- Ring bonus: +5 per ring depth (inner=+5, mid=+10, outer=+15)
- Artifact retrieval: +20 bonus
- Enemy kills: +1 per enemy killed
- shard_investment unlock: +25% total shards

Shards are awarded at run end (death, extraction, or artifact retrieval) before the run summary screen shows. The run summary displays "Shards earned: +N".

## Permanent Unlocks

- **Tier 1 (50 shards):** extra_stamina (+10 max stamina), tougher_start (+8 max HP), silver_sense (15 starting silver), quick_recovery (-0.1s stagger)
- **Tier 2 (120 shards):** veteran_dodge (+30ms i-frames), resonance_memory (carry random common modifier), deep_pockets (+5% loot), inner_knowledge (inner contract -1)
- **Tier 3 (250 shards):** warden_lore (phase thresholds visible), shard_investment (+25% shards), artifact_echo (carry rare modifier on artifact), itinerant_legacy (Legacy title cosmetic)

## Key Changes

- `game_state.gd` — New fields: resonance_shards, resonance_spent, permanent_unlocks, last_run_shards_earned. Save version v10 with migration guard. Shard earning and permanent unlock purchase/query API. Shards awarded in extract(), die_in_run(), retrieve_artifact(). silver_sense applies in start_run(). artifact_echo stores rare modifier on artifact retrieval.
- `data_store.gd` — Loads permanent_unlocks.json, exposes get_permanent_unlocks() and get_permanent_unlock(id) lookups.
- `permanent_unlocks.json` — New data file with 12 unlocks (id, name, description, flavor, tier, cost, stat, value).
- `player_controller.gd` — recalculate_modifiers() applies tougher_start (+8 HP) and extra_stamina (+10 stamina) permanent unlocks.
- `modifier_manager.gd` — On run start, applies resonance_memory (random tier-1 modifier) and artifact_echo (stored rare modifier).
- `reward_system.gd` — deep_pockets permanent unlock adds +5% loot bonus.
- `main.gd` — inner_knowledge reduces inner ring contract target by 1 (min 2).
- `flow_ui.gd` — Resonance Shrine panel (setup, show, refresh, purchase handler), shrine button in sanctuary prep screen, shrine visibility in all screen transitions.
- `run_summary.gd` — Shows "Shards earned: +N" and Legacy title if unlocked.

## Deferred to M+1

- Animated shard counter / particle effects on shard award
- Shrine NPC dialogue tree (Genn-style flavor reactions)
- Unlock tier gating (require N tier-1 unlocks before tier-2)
- Visual unlock tree / progression map
