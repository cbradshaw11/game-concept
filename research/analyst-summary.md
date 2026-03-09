# Analyst Research Summary
## HEARTHWARD Game Design Research Phase

**Date**: 2026-03-09
**Method**: 6 parallel research agents using training-data synthesis (knowledge cutoff August 2025)

---

## MIRA COLDWELL — RuneScape Design Pillars

**Core findings:**
- The idle/ambient feel is intentional design — low-attention input, variable reward, sustainable sessions ("boring" is a retention feature)
- Classless system = self-authored identity through accumulated choices over hundreds of hours
- OSRS beat RS3 2-4x on concurrent players not because of nostalgia but because players were voting on values: friction = product, player governance, no P2W, authentic economy
- Quest writing is the PRIMARY re-engagement hook — players return to finish quest chains, not to grind skills
- The OSRS polling system (75% approval required for major changes) is valued because it prevents catastrophic trust violations, not because it produces optimal design
- 3 design principles any RuneScape-inspired game MUST honor: (1) irreducible cost of progression, (2) self-authored identity, (3) structurally enforced developer-player trust

**Key quote**: "RuneScape is not a game about combat or skills or quests. It is a game about self-directed accumulation in a shared persistent world where every unit of progress is a unit of identity."

---

## DEV OKAFOR — Cross-Genre Hybrid Mechanics

**Top 5 mechanic transplants (ranked):**

1. **Designed Dual-Mode Play** (Idle/Incremental) — Highest-fidelity match to RuneScape's existing DNA. Explicitly support Active Mode (faster XP, rare drops, exclusive recipes) and Passive Mode (offline, volume, standard goods). They unlock DIFFERENT things. Production chains bridge the modes.

2. **Seasonal Environmental Pressure** (Survival Crafting) — Seasons change which resources are abundant, which skills are in demand, which zones are accessible. Higher skill levels REDUCE seasonal pressure. Creates permanent demand cycles.

3. **Skill-Specific Roguelike Ordeal Dungeons** — Opt-in dungeons with suspended death rules. Boons interact with your existing skill levels in unusual ways. Earn permanent "Insight" upgrades. Solves endgame for maxed players.

4. **Persistent Workshop Infrastructure** (Factory/Automation) — Best as optional guild-level system. Resource chains with maintenance decay. Low-level resources never become economically obsolete.

5. **Homestead with Procedural Settlers** (Colony Sim) — Highest ceiling, highest risk. Post-launch expansion.

**Key recommendation**: Dual-Mode Play + Seasons + Ordeal Dungeons form a coherent system where each creates demand for the others.

---

## SABLE NG — Post-Mortem Analysis

**Games analyzed**: Albion Online, Melvor Idle, Genfanad, Torn, IdleOn, private server ecosystem

**Three dominant failure modes:**

1. **Content Floor Collapse** — "There is nothing to do after week two." Minimum viable content mass is significantly higher than teams estimate going in.

2. **Audience Schizophrenia** — Building for everyone (PvP + PvE + social + casual) with limited resources means serving no one adequately. Pick one audience and build for them completely.

3. **Monetization That Reads as Hostile** — The RuneScape audience has a finely tuned hostility detector for pay-to-win. Design payment as optional acceleration on top of complete free progression, not as pressure to pay.

**Three design traps:**
- Cloning the surface without the depth (Genfanad)
- Full-loot PvP as the endgame gate (Albion)
- Launching multiplayer before you have the player mass to sustain it (ghost town problem)

**Market gap**: RuneScape-depth game with modern solo/co-op pacing, clean economy that doesn't advantage veterans and bots, monetization the community can respect.

---

## THEO WARSINSKI — Indie RPG/MMO Trends 2022-2025

**Top 5 trends:**
1. The "Cozy MMO" emergence — socialization without combat pressure
2. Deeply personal progression — "your character is a document of your choices"
3. Skill-based / non-class progression revival (OSRS growing, Brighter Shores interest)
4. The "Solo MMO" — MMO world design with single-player pacing
5. Browser-based and ultra-lightweight MMO nostalgia

**Biggest unmet player desire**: "I want an MMO-sized world I can inhabit alone, on my schedule, with progression that feels personal to me."

**5 market gaps:**
1. Solo-first skill-based persistent RPG (browser-accessible, 20-min sessions, async multiplayer traces)
2. Humor and personality in MMO-adjacent RPGs (currently zero at scale)
3. Crafting as PRIMARY progression spine (not combat afterthought)
4. Asynchronous multiplayer in a persistent world (Dark Souls traces model)
5. The "20-minute session MMO"

---

## PRIYA SHENKAR — Tech Stack Feasibility

**Recommendation**: Godot 4 + Node.js (600ms tick) + PocketBase + Hetzner VPS

**Engine rationale**: Godot 4 — free, MIT license, no vendor risk, GDScript velocity, excellent 2D/isometric tooling, HTML5 export available, large community post-Unity crisis. Unity out (runtime fee crisis, trust destroyed). Phaser out (framework ceiling too low for open world). Custom engine out (building engine instead of game).

**Backend architecture**:
- Node.js game server: 600ms tick loop (OSRS-inspired), WebSocket. Handles world state in memory.
- PocketBase: single Go binary, SQLite, auth + persistence + REST API, zero ops overhead. Handles character data, inventory, market listings.
- Hetzner VPS: $10-20/mo for alpha, $40-60/mo at launch

**Biggest technical risk**: World state consistency on shared interactions. Server-authoritative inventory from day 1 — non-negotiable. Design idle calculation as delta-time catch-up on login (not continuous offline simulation).

**Build order**: Months 1-3 single-player (no backend), 4-6 PocketBase persistence, 7-9 multiplayer game server, 10-12 closed alpha at 50 concurrent.

---

## ROWAN ELLERY — Player Psychology of Progression

**Three core psychological hooks in RuneScape:**

1. **Variable Ratio Reinforcement** (Skinner/Ferster 1957; Schultz et al. 1997) — Tiered drop tables (floor always produces something, ceiling always open). Multi-layered: immediate drops + level milestone arcs + rare events. Design: every meaningful action produces output from a tiered possibility space.

2. **IKEA Effect** (Norton, Mochon & Ariely 2012) — Self-built objects valued ~50% higher than pre-built equivalents. RuneScape's classless system maximizes IKEA effect on the entire character (not just periphery). Ironman mode's popularity is direct behavioral evidence.

3. **Social Status / Relatedness** (Yee 2006; Veblen 1899; Ryan & Deci 2000) — Skill capes, hiscores, rare items as Veblenian status signals. Social legibility of personal achievement drives sustained engagement independent of intrinsic enjoyment.

**What makes a player STAY through a grind:**
- Goal Gradient Effect (Hull 1932; Kivetz et al. 2006) — motivation increases near milestones. **Milestone density in the 30-70% zone is the single most important structural decision for grind retention.**
- Meaningful choices with real trade-offs (not cosmetic)
- Social scaffold from hour 1 (not just at endgame)

**Three quit triggers:**
1. Motivation Trough — no milestones 30-70% of arc
2. Social Isolation — friend network erodes, world feels empty
3. Goal Dissolution — major goal completed, no clear next goal

**Grind pace sweet spot**: 20-200 hours per major milestone, sub-milestones every 5-10% of arc.

**RuneScape vs WoW-style gating**: Soft gates (you CAN enter but will struggle) preserve SDT autonomy. Hard gates (you CANNOT enter until level X) create extrinsic motivation and overjustification effect — destroy intrinsic motivation over time.
