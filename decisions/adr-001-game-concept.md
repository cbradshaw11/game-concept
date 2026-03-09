# ADR-001: Game Concept Decision Record
## HEARTHWARD — Conflict Resolutions & Voting Record

**Date**: 2026-03-09
**Process**: 6-analyst research → 5-architect design → deliberation synthesis
**Status**: DECIDED — All conflicts resolved, unanimous consensus on all 5

---

## CONTEXT

A multi-agent research and design process produced 5 independent architect proposals spanning core loop/skills (Cassian Vole), world structure (Isolde Farr), economy (Marcus Tull), quests/narrative (Yael Dross), and MVP scope (Petra Haslow). 5 conflicts were identified between proposals and resolved through deliberation.

---

## CONFLICT 1: SKILL COUNT — 18 vs 8

**Cassian proposed**: 18 skills in 4 tiers
**Petra proposed**: 8 skills for MVP

**Resolution**: **12 skills at MVP**
The economic web depth Cassian describes is load-bearing for character identity, Blight Run personalization, and market specialization — 8 skills cannot generate that. But Petra's 12-month timeline is honest. The resolution is tiered launch architecture: ship 12 skills, add 6 in post-launch expansion. The 12-skill set runs all 5 economic chains meaningfully and preserves Cassian's tier architecture.

**Skills cut to post-launch**: Brewing, Farming, Cartography (split from Wayfinding), Architecture, Inscription (split from Runecraft), Enchanting.

**Vote**: 5/5 unanimous (Cassian and Petra: reluctant accepts)

---

## CONFLICT 2: GAME TITLE

**Cassian proposed**: Veilcraft
**Marcus proposed**: Hearthmark
**Yael proposed**: Hearthfall
**Isolde named the world**: Cauldron

**Resolution**: **HEARTHWARD** (world: CAULDRON)

Veilcraft names a mechanic (becomes in-universe term for Resonance-working). Hearthmark implies trading stamp (the game is not primarily commerce). Hearthfall front-loads the wrong emotional gravity for a warmth-earns-darkness tone. Hearthward — "moving toward home, not having arrived there yet" — is directional, matches the Itinerant identity, contains Yael's warmth, and is distinct in market. Cauldron (Isolde's word) survives as the world name — the best word in all five documents.

**Vote**: 5/5 unanimous (Marcus and Cassian: reluctant accepts)

---

## CONFLICT 3: BLIGHT RUNS vs ORDEAL DUNGEONS

**Cassian proposed**: Blight Runs as differentiating mechanic (skill-web-generated dungeon)
**Petra proposed**: 3 fixed Ordeal Dungeons within MVP scope

**Resolution**: **Both ship at MVP. Blight Runs in modular form.**

Blight Runs are the most original idea across all proposals and the game's thesis made playable. At MVP, implementation is semi-modular: 50+ pre-authored encounter modules tagged with skill requirements, dynamically weighted-selected toward the player's top skills. This bounds technical complexity (routing algorithm, not generative system) while preserving the concept intact. 3 Ordeal Dungeons remain as fixed narrative set-pieces (different function: story context, not personalization). Full procedural Blight generation is the 18-month milestone.

**Vote**: 5/5 unanimous (Petra: reluctant accept on scope)

---

## CONFLICT 4: ECONOMIC DEPTH vs MVP SCOPE

**Marcus proposed**: Full 5-chain economy with tiered marketplace
**Petra proposed**: No player trading at MVP

**Resolution**: **Local Stall + Faction Buying Agents + Workshop Decay. No player trading.**

Player-to-player trading at MVP creates: wealth concentration before anti-monopoly tuning, ghost-economy risk (broken markets are worse than no market), and bad-actor moderation burden. The 5-chain production logic, workshop maintenance decay (permanent low-tier demand), Local Stall, and NPC Faction Buying Agents survive. These are Marcus's best ideas and they function without player population. Supply Provenance markers and anti-monopoly systems are built silently at MVP, activated post-launch.

**Vote**: 5/5 unanimous (Marcus: reluctant accept)

---

## CONFLICT 5: QUEST COUNT

**Petra proposed**: ~12 quests (12 excellent > 20 adequate)
**Yael proposed**: Two serial arcs (13 quests) plus standalones

**Resolution**: **15 quests. Mercer Letters (7) as MVP serial arc. The Saltborn (6) as first post-launch expansion.**

The serial arc amortization argument is sound: 7 Mercer Letters quests share world-building costs (set in Saltsmouth, which exists anyway). Petra's principle is honored — quality over quantity — with 15 quests receiving full authoring attention. The Saltborn has a confirmed post-launch slot (Month 13-18). The onboarding quest "A Reasonable Request" ships intact.

**Vote**: 5/5 unanimous

---

## RESEARCH SOURCES

Six research analysts contributed to the architect briefing:
- **Mira Coldwell**: RuneScape design pillars, OSRS/RS3 split analysis, 3 design principles
- **Dev Okafor**: Cross-genre mechanic transplants (idle, survival, roguelike, factory, colony sim)
- **Sable Ng**: Post-mortems (Albion Online, Melvor Idle, Genfanad, Torn, IdleOn, private servers)
- **Theo Warsinski**: Indie RPG/MMO trends 2022-2025, 5 market gaps identified
- **Priya Shenkar**: Tech stack feasibility (Godot 4 + Node.js + PocketBase recommendation)
- **Rowan Ellery**: Player psychology (variable ratio reinforcement, IKEA effect, SDT, quit triggers)

Full analyst reports saved in `/research/`.

---

## KEY PRINCIPLES CONFIRMED IN DELIBERATION

1. Progression must have irreducible cost — the grind IS the reward mechanism (Mira)
2. Player identity must be self-authored, not assigned (Mira, Cassian)
3. Developer-player trust compact must be structurally enforced — no P2W, no progression throttling (Mira, Sable)
4. Design for 500 players, not 5000 (Petra, Sable)
5. The idle layer ships polished or nothing ships (Petra)
6. 12 excellent quests beat 20 adequate ones (Petra, Yael)

---

## WHAT NOT TO BUILD (Sable's failure pattern summary)

- Do not clone RuneScape's surface without the depth — build systems that generate emergent goals
- Do not make full-loot PvP the endgame gate
- Do not launch multiplayer before content mass is sufficient
- Do not design monetization that throttles free progression
- Do not design for the players you want — design for the players you have at launch
