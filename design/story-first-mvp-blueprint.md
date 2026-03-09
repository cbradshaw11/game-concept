# Story-First MVP Blueprint
## The Long Walk

Date: 2026-03-09
Status: Active implementation plan
Target: PC MVP (single-player first)

## 1. MVP Outcome
Deliver a playable game where the player:
1. Starts in safe zone.
2. Progresses through Ring 1, Ring 2, and Ring 3.
3. Defeats the Outer Warden.
4. Extracts the Artifact to complete the main arc.

Main arc completion target: 8 to 12 hours.

## 2. Core Loop
1. Prepare at home base (shop, loadout, contract).
2. Push into ring encounters.
3. Choose risk: continue deeper or extract.
4. Return to base and bank progression.
5. Unlock next gate, repeat.

## 3. Combat Design (MVP)
### Player verbs
- Attack
- Dodge
- Guard

### Weapons
- Blade: fast, low commitment
- Polearm: spacing and poise pressure
- Bow: ranged control and weak point punish

### Resources
- Health
- Stamina
- Poise

### Win condition for combat quality
- Telegraphs are readable.
- Dodge timing feels reliable.
- Guard and poise create tactical tradeoffs.

## 4. Ring Progression
1. Ring 0: Sanctuary
- Safe zone and progression hub.

2. Ring 1: Inner
- Low threat enemies.
- Introduces extraction and loss rules.

3. Ring 2: Mid
- Mixed enemy packs.
- Adds hazard tiles and ambush setups.

4. Ring 3: Outer
- Elite variants and boss approach path.
- Warden boss encounter.

## 5. Story Arc (MVP)
1. Prologue
- Settlement explains the Artifact mission.

2. Discovery
- Recover map shard from Ring 1 station.

3. Complication
- Ring 2 reveals prior expedition failure and faction conflict.

4. Climax
- Ring 3 Warden fight and Artifact extraction.

5. Resolution
- Return to Sanctuary with Artifact, world state shifts, credits.

## 6. Economy and Progression Constraints
- Keep economy minimal and combat-support only.
- Crafting limited to consumables and upgrade components.
- No player trading in MVP.
- No broad life-skill tree in MVP.

## 7. System Modules
1. CombatCore
2. RingDirector
3. EncounterTemplates
4. LootEngine
5. ProgressionBanking
6. ContractSystem
7. SaveLoad
8. Telemetry

## 8. Agent-Driven Build Workflow
1. technical-analyst
- Finalize acceptance criteria and edge cases per module.

2. software-architect
- Define interfaces and data contracts.

3. implementer
- Build in vertical slices.

4. ux-expert
- Tutorial, HUD, accessibility defaults.

5. verifier
- Break assumptions and enforce quality gates.

6. docs-writer
- Keep spec and changelog synchronized with implementation.

## 9. 10-Week Delivery Plan
1. Weeks 1-2: Combat sandbox
- Character, camera, input, hit events.

2. Weeks 3-4: Enemy and ring scaffolding
- Ring 1 and Ring 2 encounter templates, 4 enemy archetypes.

3. Weeks 5-6: Progression and extraction
- Banking, death-loss, base upgrades v1.

4. Weeks 7-8: Ring 3 and Warden boss
- Boss phases and completion flag.

5. Weeks 9-10: Narrative beats and polish
- Story delivery, tutorial, tuning, bug hardening.

## 10. Definition of Done (MVP)
1. Main arc can be completed start to credits.
2. Average internal clear time is within 8 to 12 hours.
3. No blocker bugs in combat, save/load, or quest progression.
4. Stable 60 FPS on target test hardware in combat scenes.
5. Verifier pass completed on all critical systems.

