---
id: M3
title: Combat Model
status: done
---

## Description
Make the game loseable. Complete the combat model end-to-end: player HP, enemy damage output, live weapon stats, guard damage reduction, dodge invulnerability frames, player poise, combat HUD, death screen, Ring 1 balance pass, and a full combat test suite.

## Entry Criteria
- [x] All 17 M1/M2 tickets in .tickets/closed/
- [x] Sanctuary-to-Ring1 loop runs without crashing
- [x] CI headless tests pass (TASK-209 confirmed)

## Exit Criteria
- [x] Player HP reaches 0 → death state fires → unbanked rewards cleared
- [x] Enemies deal damage using their `damage` field from enemies.json
- [x] Weapon selection in Sanctuary changes combat damage (from weapons.json, not hardcoded)
- [x] Guard input reduces incoming damage by a defined amount
- [x] Dodge input grants an invulnerability window; hits during window deal 0 damage
- [x] Player poise tracked; poise break triggers stagger
- [x] Combat HUD displays current HP, stamina, and poise in real time
- [x] Death screen shows run summary (encounters cleared, rewards lost)
- [x] Ring 1 enemy HP/damage tuned based on real combat numbers (documented in PR)
- [x] Full combat loop test suite passes in CI headless run
- [x] No regression on Ring 1 extraction path

## Demo Scenarios
1. Enter Ring 1, take damage from enemies, die — confirm unbanked rewards cleared
2. Enter Ring 1 with blade_iron, verify 14 damage per attack
3. Hold guard while being hit, verify damage reduction
4. Dodge at the right moment, verify 0 damage received
5. Take enough hits to break poise, verify stagger
6. Complete Ring 1 and extract successfully (regression check)

## Verifier Sign-off
- Pending

## Tasks
- [ ] TASK-301 Player HP and death state
- [ ] TASK-302 Enemy damage output
- [ ] TASK-303 Weapon stat integration
- [ ] TASK-304 Guard damage reduction
- [ ] TASK-305 Dodge invulnerability frames
- [ ] TASK-306 Player poise tracking and stagger
- [ ] TASK-307 Combat HUD (HP, stamina, poise)
- [ ] TASK-308 Death screen and run summary
- [ ] TASK-309 Ring 1 combat balance pass
- [ ] TASK-310 Full combat loop test suite
