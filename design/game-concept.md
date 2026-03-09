# HEARTHWARD
## A Game Set in the World of CAULDRON

**Version**: 1.0 — Post-deliberation unified concept
**Date**: 2026-03-09
**Process**: 6-analyst research phase + 5-architect design phase + deliberation synthesis

---

## ELEVATOR PITCH

A skill-based idle RPG where you build a persistent character across short daily sessions, grinding a living from a world still fractured by an ancient catastrophe. RuneScape's satisfying depth compressed for real life, with async multiplayer traces that make the world feel inhabited without requiring other players to be online.

---

## WORLD PREMISE

Cauldron is a continental basin enclosed by the Rimwall mountains, a world shaped by the Compact civilization that mastered Resonance — the art of working with the world's material grain to grow, build, and connect. Three centuries ago, the Unspooling fractured the Resonance mid-sentence. Infrastructure that should have been eternal is intact but interrupted: roads that go nowhere, aqueducts feeding empty basins, forges whose heat never dies but whose purpose was lost. You are an Itinerant — a post-Compact wanderer with recognized right of passage everywhere in Cauldron — arriving in a world that is not broken so much as mid-sentence, and learning to work the grain of a world still deciding what it becomes.

---

## TONAL IDENTITY

A historian who drinks too much and tells the truth anyway. Warmth earns darkness. Specificity earns absurdity. No Chosen One framing. The player is a person who arrived somewhere.

---

## FINAL SKILL LIST — 12 SKILLS

**Tier 1 — Gathering (4 skills)**
- Woodcutting
- Mining
- Fishing
- Foraging (herbalism, fungi, wild materials)

**Tier 2 — Processing (3 skills)**
- Cooking (raw food → sustenance and alchemy inputs)
- Smelting (ore → refined metal)
- Tanning (raw hides → leather and binding materials)

**Tier 3 — Crafting (3 skills)**
- Smithing (metal goods, tools, combat equipment)
- Crafting (composite goods: furniture, rope, cloth, containers)
- Runecraft (knowledge goods, inscription, advancement materials)

**Tier 4 — Mastery (2 skills)**
- Combat (unified: melee/ranged/magical — specialization through equipment and Insights)
- Wayfinding (navigation, cartography, seasonal resistance, region unlocking)

**Post-Launch Expansion Skills (6):** Brewing, Farming, Cartography, Architecture, Inscription, Enchanting.

---

## CORE GAMEPLAY LOOP

You arrive in the Settling with a name, a pack, and no particular destiny. You gather raw materials, process them into goods, and craft those goods into things the world needs. Two modes of play serve different hours of your day: Active Mode rewards attention with faster XP, rare drop chances, and exclusive recipes; Passive Mode runs while you are away, generating volume goods and advancing long timers. These modes unlock *different things* — not the same things at different speeds. Production chains bridge the modes: Passive foraging feeds Active cooking which feeds Passive fermentation which feeds Active runecraft. The waiting is load-bearing.

Every 6 real weeks, the world enters a new Resonance State (Flux, Settle, Withdrawal, Deep), changing which zones are accessible, what materials are abundant, and what the economy needs. Higher skill levels reduce Resonance State friction — mastery is weather-proofing.

---

## THE DIFFERENTIATING MECHANIC: BLIGHT RUNS

When a Blight event descends on a region, a Blight Dungeon appears for a limited window. The dungeon reads the player's current skill web and selects 6-8 encounter modules from a pre-authored pool of 50+, each tagged to specific skills, weighted toward the player's highest-trained skills.

A player deep in the crafting tree faces material puzzles, structural failures, and resource scarcity challenges. A Combat-and-Wayfinding specialist faces territorial and navigational hazards. Completing a Blight Run awards Insights: permanent passive bonuses whose specific effect depends on the skills that were tested. No two players' Insight collections are identical, because no two players' skill webs are identical.

**Your skill web is the dungeon generator.**

*MVP implementation: modular weighted selection from 50+ pre-authored encounter modules (not full procedural generation). Full procedural generation is the 18-month milestone.*

---

## WORLD STRUCTURE

| Zone | Character | Access |
|---|---|---|
| The Settling | Starting valley, Compact ruins, tutorial density | Open from day 1 |
| The Ashfen | Wetland biome, Fishing/Foraging abundance, murky questlines | Wayfinding 20+ |
| The Cinder Range | Volcanic highlands, ore-rich, Smelting/Smithing economy | Mining 30+, Wayfinding 30+ |
| The Verdant Congress | Ancient forest, rare woods, Runecraft materials | Wayfinding 40+ |
| The Saltback Coast | Trade hub Saltsmouth, Drift Market, Mercer Letters arc | Wayfinding 25+ |
| The Greyshelf Uplands | Highland plateau, home of 3 Ordeal Dungeons | Quest-gated + Wayfinding 50+ |
| The Unspooled Margin | Edge zone, endgame lore apex, Resonance at its most raw | Wayfinding 75+, Runecraft 60+ |

**Resonance States** (replace seasons): Flux (6 wks), Settle (6 wks), Withdrawal (6 wks), Deep (6 wks). Each state shifts zone behavior, resource availability, and Blight frequency.

**Homestead**: A real location in the world, visible to other players, recruitable NPC settlers from factions.

---

## PROGRESSION ARCHITECTURE

Milestone density follows Cassian's model:
- Levels 1-20: Dense (every 4 levels), gift-phase, establish investment
- Levels 20-40: Identity arc, first trade-offs, Passive Rail options emerge
- Levels 40-60: HIGHEST DENSITY (every 3-4 levels) — the dangerous zone, overcrowded with Branch Unlocks
- Level 50: "Journeyman" — named threshold with ceremony, hiscore visibility
- Levels 60-75: Rarer but heavier milestones, skill capes visible on horizon
- Levels 75-90: Sparse and named — lore attached, NPC reaction, world acknowledgment
- Levels 90-99: Countdown density, every level a milestone, community-shared progress

---

## ECONOMY

**Production chains**: Iron (combat supply), Green (sustenance/alchemy), Stone (infrastructure), Wood (fuel/craft), Knowledge (advancement goods). These chains intersect at processing and crafting tiers.

**MVP market infrastructure**:
- Local Stall (day 1, no fee, NPC demand buys on tick cycle)
- Faction Buying Agents (standing buy orders from regional factions)
- Workshop Maintenance Decay (permanent low-tier raw material demand)
- Masterwork Items (Active-mode-only rare craft outcomes — inventory trophies at MVP)

**New player value**: Low-tier raw materials have permanent structural demand from workshop decay. New players are economically relevant from day 1.

**Post-launch**: Regional Exchange, Grand Market, player-to-player trading, Supply Provenance lineage markers, Guild market share mechanics.

---

## QUEST SYSTEM

**Structure**: 20-minute three-beat model for all quests — Setup + Complication → The Work → Resolution + Resonance Line. The Resonance Line (the closing beat that reframes what you did) is mandatory.

**MVP Quest Inventory — 15 quests**:
1. "A Reasonable Request" — Onboarding quest. Hook: something knows your name. Not the player's name. The character's name.
2. The Mercer Letters (7 quests) — Political conspiracy in Saltsmouth. Permanent visible world changes to the city on completion.
3. Three Ordeal Prequel Quests (1 per dungeon) — Contextualizes each Greyshelf dungeon through a questline.
4. Four Standalone Side Quests — Full three-beat structure, full authoring attention.

**Post-launch**: The Saltborn (6 quests, coastal horror, first narrative expansion — 6 months post-launch).

**Reactivity**: NPC knowledge states propagate. Environmental changes are permanent. Faction standings shift quest availability, economy, and Blight Run module pools.

---

## ASYNC MULTIPLAYER LAYER (MVP)

No real-time multiplayer at launch. World feels inhabited through:
- Cartography Marks (surveyor annotations by other players, visible on map)
- Death Records (marker where players died, optional notes)
- Drift Market (player-named goods board, no direct trading)
- Faction Notice Boards (quest/bounty postings with player names)
- Footprints / Path Memory (high-traffic routes become visible trails)
- Homesteads (other players' plots visible in the world)

---

## PLATFORM AND TECH STACK

| Layer | Tool |
|---|---|
| Game engine | Godot 4 |
| Game server | Node.js + ws (600ms tick loop) |
| Persistence | PocketBase (SQLite) |
| Hosting | Hetzner VPS (~$10-20/mo alpha, ~$40-60/mo launch) |
| Distribution | itch.io (alpha), Steam (launch) |
| Target platforms | Desktop: Windows, macOS, Linux |

**Not at launch**: Mobile, browser export, console.
**Critical architectural note**: Idle layer uses delta-time catch-up formula on login (not continuous offline simulation). Server-authoritative inventory from day 1 of multiplayer — non-negotiable.

---

## MVP SCOPE

### IN AT LAUNCH
- 12-skill system (4-tier architecture, dual-mode Active/Passive)
- Blight Runs (modular, 50+ pre-authored encounter pool)
- 3 Ordeal Dungeons (hand-authored, Greyshelf Uplands)
- 7 zones (all accessible)
- 4 Resonance States (one full cycle)
- 15 quests (onboarding + Mercer Letters + 3 Ordeal Preludes + 4 standalones)
- Local Stall + Faction Buyers + Workshop Decay economy
- Async multiplayer traces (all 6 listed above)
- Homestead (basic: plot + structure)
- Milestone architecture (Journeyman at 50, skill capes at 99)
- Steam page live by Month 10

### OUT AT LAUNCH
- Skills 13-18 (Brewing, Farming, Cartography, Architecture, Inscription, Enchanting)
- The Saltborn questline
- Player-to-player trading
- Regional Exchange / Grand Market
- Guild systems
- PvP of any kind
- Factory / automation systems
- Colony sim mechanics
- Mobile / browser export
- Voice acting

---

## 12-MONTH ROADMAP

| Phase | Months | Deliverable |
|---|---|---|
| Single-Player Prototype | 1-3 | 12 skills, dual-mode loop, The Settling zone, onboarding quest, Local Stall, no multiplayer |
| Backend + Persistence | 4-6 | Node.js tick server, PocketBase, Passive Mode offline, Homestead (basic), all 7 zones, Resonance States |
| Game Server + Async | 7-9 | Async trace layer live, Blight Run system (modular), Faction Buyers, 3 Ordeal Dungeons + prequel quests, Steam page live |
| Closed Alpha | 10-12 | Mercer Letters complete, 4 standalone quests, economy balanced, anti-bot layer verified, 500-player load tested |

**Post-launch Month 13-18**: The Saltborn, Regional Exchange, Skills 13-15.
**Post-launch Month 19-24**: Grand Market, Skills 16-18, full procedural Blight generation.

---

## THREE RULES (Per Petra Haslow, confirmed in deliberation)

1. **The idle layer ships polished or nothing ships.** Every other mechanic is optional at MVP. This one is not.
2. **Design for 500 players, not 5000.** Infrastructure scales up; design assumptions do not scale down.
3. **12 excellent quests beat 20 adequate ones.** Cut quest count before cutting quest quality.

---

## THE GAME'S IDENTITY (Per Product Owner synthesis)

Three things define this game. Everything else serves these three. If a future decision conflicts with one of these three, the decision loses.

1. **The dual-mode loop**: Active and Passive unlock *different things*.
2. **Blight Runs**: Your skill web is the dungeon generator.
3. **The Resonance Line**: The closing beat of every quest reframes what you just did.

The world's name is Cauldron. Ship something worthy of it.
