# M17 — Narrative Layer: The Long Walk

**Status:** COMPLETE  
**Date Authored:** 2026-03-24  
**Date Completed:** 2026-03-25  
**Author:** shadowBot (overnight session)  
**Scope:** Prologue, ring lore, NPC dialogue, flavor text, environmental storytelling

---

## Overview

M17 adds the story skeleton to the otherwise gameplay-complete MVP. The world has rules but no voice. M17 gives it one.

The tone guide (from the design doc): *"A historian who drinks too much and tells the truth anyway. Warmth earns darkness. Specificity earns absurdity. No Chosen One framing. The player is a person who arrived somewhere."*

This milestone does not require new scenes or mechanics. It adds **data** — a `narrative.json` file — and hooks it into existing UI surfaces via a new `NarrativeManager` autoload.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Write prologue sequence (3 beats, screen text + voice flavor) | DONE (this doc) |
| T2 | Write ring entry flavor text (sanctuary, inner, mid, outer) | DONE (narrative.json) |
| T3 | Write NPC dialogue — Archivist Genn (vendor NPC) | DONE (narrative.json) |
| T4 | Write death flavor text — narrative tone pass | DONE (narrative.json) |
| T5 | Write victory/extraction flavor text | DONE (narrative.json) |
| T6 | Write lore fragments (collectible notes found in rings) | DONE (narrative.json) |
| T7 | Write Warden boss intro monologue (Ring 3 boss gate) | DONE (narrative.json) |
| T8 | Scaffold NarrativeManager.gd autoload | DONE (game/autoload/narrative_manager.gd) |
| T9 | Hook prologue into main.gd startup flow | DONE (main.gd _ready, prologue_seen flag) |
| T10 | Hook ring entry text into RingDirector.gd | DONE (main.gd _begin_run via NarrativeManager) |
| T11 | Hook vendor dialogue into vendor UI | DONE (get_vendor_greeting / get_vendor_purchase_line) |
| T12 | M17 test suite | DONE (6 test files, 108 assertions, all green) |

---

## World Context (for tone consistency)

**Setting:** Post-Unspooling Cauldron. The Compact fell three centuries ago — infrastructure intact but interrupted. Roads that end. Forges that never went cold. Society rebuilt around salvage, not invention.

**The Long Walk** = the player's mission. You're an Itinerant (recognized right of passage everywhere) hired/compelled to go ring by ring, retrieve the Artifact, bring it back. You are not special. You are competent, maybe lucky, and willing to try.

**The Sanctuary** = a waystation. Partially restored. The Archivist runs it — Genn, an older woman who has watched many Itinerants come through. She does not over-explain. She tells you what she knows and lets you make your own choices.

**The Rings** = concentric zones around the Artifact's resting place. Each ring feels like a different era of abandonment. Inner: recent, contested, almost livable. Mid: older, stranger, the architecture doesn't quite make sense anymore. Outer: something happened here that the record doesn't explain.

---

## Prologue Sequence (3 Beats)

### Beat 1 — Arrival
*Screen: dark. Text fades in.*

> The road brought you here. Or you brought yourself — by this point the distinction matters less than it used to.
>
> A waystation. Firelight. The smell of something being cooked that might generously be called stew.
>
> Someone is waiting.

### Beat 2 — The Briefing (Archivist Genn speaks)
*Screen: Sanctuary hub. Genn stands near the fire.*

> "I'm Genn. I've been stationed here since before the last expedition stopped coming back. That's the honest version."
>
> "The Artifact is in the Outer Ring. The Rings between here and there are... contested. Don't ask me by what — the records on that got complicated."
>
> "Three extractors made it to the Mid before I stopped counting. You'll get their notes if you find them. Whether that helps you or just tells you how they died is hard to say in advance."
>
> "Contracts pay silver. Silver buys upgrades. Upgrades are the difference between 'made it back' and 'became part of the record.' Any questions?"

*[Player selects: "No questions." / "What's the Artifact?" / "Why me?"]*

**→ "What's the Artifact?"**
> "Something the Compact built at the end of their good period. It stabilizes Resonance in a radius. If it works, this whole waystation becomes a livable settlement again. If it doesn't... well. I've been wrong before."

**→ "Why me?"**
> "You were walking past. That's usually how these things go."

**→ "No questions."**
> "Good. I appreciate efficiency."

### Beat 3 — First Departure
*Player begins first run. Text appears at Ring 1 gate.*

> The Inner Ring isn't far. Nothing out here is. The problem is everything between here and there has opinions about your presence.
>
> *Extract when it feels wrong. The silver will wait. The dead don't get paid.*

---

## NarrativeManager.gd — Spec

```gdscript
# autoload: NarrativeManager
# Reads from narrative.json
# API:

# Get prologue beats (returns Array of Dicts)
func get_prologue() -> Array

# Get flavor text for a ring event
# event_type: "entry" | "extraction" | "death" | "warden_gate"
# ring_id: "sanctuary" | "inner" | "mid" | "outer"
func get_ring_text(ring_id: String, event_type: String) -> String

# Get random NPC dialogue line for a given NPC + context
# npc_id: "genn_vendor" | "genn_run_return" | "genn_death_return"
func get_npc_line(npc_id: String) -> String

# Get a lore fragment by ID (or random if id == "")
func get_lore_fragment(id: String = "") -> Dictionary

# Get warden intro monologue (returns Array of Strings, displayed sequentially)
func get_warden_intro() -> Array
```

---

## Ring Entry Flavor Text

### Sanctuary (returning)
- "The stew is worse every time. Genn takes this as a point of pride."
- "The fire's still going. Small mercies."
- "Same waystation. Different you. Hard to say if that's better."

### Inner Ring — entry
- "The Inner Ring has the particular smell of a place that used to be lived in and isn't quite anymore. Ash and old cooking. Something sweet underneath that you decide not to investigate."
- "Grunt tracks in the mud. Recent. They know someone new is working the Ring."
- "The architecture here is almost normal. Roads that lead places. Buildings with roofs. The Compact knew what they were doing, right up until they didn't."

### Mid Ring — first entry
- "The Mid Reaches feel older than they should. The road gets stranger the further you go — stones that don't match each other, archways that start and don't finish. The Compact was building something and then stopped, and the thing they were building kept going without them for a while."

### Mid Ring — repeat entry
- "You know this stretch now. That doesn't make it easier. It just makes it familiar, which is a different category of problem."
- "The ash flankers hunt in overlapping patterns. You learned that the expensive way."

### Outer Ring — first entry
- "Whatever happened here, the record calls it an 'incursion event' and then goes quiet. You've read enough Compact documents to know that 'incursion event' is what they wrote when they didn't want to describe what they actually saw."
- "The light is wrong at the edge of the Outer. Not dark — just angled differently than it should be, like the Ring is somewhere else and also here at the same time."

### Outer Ring — repeat entry  
- "Back again. The Outer doesn't care. It just keeps being the Outer."

---

## Genn — Vendor Dialogue Pool

### On first visit / greeting
- "Back in one piece. Good. Spend what you've got — silver's only useful if you're moving."
- "I've been keeping a tally. You're at the top of the list for longest-surviving current Itinerant. Don't read too much into that."
- "You want upgrades or are you just here to use the fire?"

### After player's first death
- "You came back. That's more than some of them managed on the first one."
- "The Inner's not forgiving of overconfidence. Now you know. Come on, let's look at your loadout."

### After player reaches Mid
- "The Mid changes people, if they let it. Most of the ones who made it back from there got quieter. Not sadder — just quieter. Like they figured out what they actually needed to say."

### After player reaches Outer
- "I won't tell you to be careful. You know the stakes. I'll just say: the Artifact was the Compact's best thing. They made it to be useful. Whatever's guarding it... made itself to stop that."

### On vendor purchase
- "Good choice."
- "That one kept the last extractor alive through mid-Ring. Probably."
- "You're thinking about this the right way."

### On vendor browse / no purchase
- "Take your time. The Ring will wait."
- "Silver spends. But so does time."

---

## Death Flavor Text — Narrative Pass

*(These supplement the existing M16 mechanical flavor texts with story-tone variants. Displayed at 50% probability alongside mechanical text.)*

### Inner Ring death
- "The Inner gets everyone eventually, if they push too hard. The question is whether you pushed far enough to learn something."
- "They found you before you found them. Adjust."
- "Three things killed more Itinerants than anything: overconfidence, underestimation, and a very specific kind of optimism that says 'just one more encounter.'"

### Mid Ring death
- "The Mid Reaches were built to be navigated. Carefully. In the direction of caution."
- "The ash flankers work in overlapping arcs. The ones who know that are the ones who talk about it afterward."
- "The Compact's records on the Mid use the phrase 'acceptable risk profile.' They were measuring for a different traveler."

### Outer Ring death
- "The Outer doesn't kill you out of malice. It kills you because it has a job and you were in the way of it."
- "You got further than most. That's real. The record shows that."
- "Something in the Outer was set to guard something. You got close enough to remind it."

---

## Victory / Extraction Flavor Text

### Inner Ring extraction
- "You learned the shape of it. That's worth more than the silver, eventually."
- "Out clean. The Inner remembers that you respect the rules."
- "Extracted. The waystation is still standing. The stew is technically still food. Acceptable."

### Mid Ring extraction
- "Mid extracted. Genn doesn't say 'I told you so' but her expression has opinions."
- "You know what the Mid Reaches look like at the back of a run now. That's something."
- "Out. Whole. The ash flankers will be angrier next time — they adapt. So will you."

### Outer Ring extraction
- "The Outer let you go. Or you took it anyway. The distinction matters more to the historians than to you."
- "Out from the Outer. Most of the people who'd want to know that you did it aren't around to ask."

### Artifact extraction (final victory)
- "It's heavier than you expected. All the important things are."
- "The Compact built this to last. It did. Whether what comes next lasts — that's on you now."

---

## Lore Fragments

*(Found as items in Ring encounters — display in a 'recovered notes' UI panel)*

### Fragment 001 — "Expedition Report, Dated Third Year Post-Unspooling"
> "The Inner Ring is passable. Repeat: passable. Take three or more. Do not push after dark. The things that hunt there hunt by hearing and they have excellent ears.
> 
> — Commissioned Itinerant Vera Sasch, Inner Survey"

### Fragment 002 — "Personal note, author unknown, found in Mid waystation wall"
> "If you're reading this you found the loose stone in the east arch. Congratulations on being thorough.
>
> The second wave is always worse than the first. Bring extra stamina tonic and ignore the gate that says 'DO NOT OPEN.' It lies. The gate you want is behind the rubble on the north approach, thirty paces from the big rock that looks like a sleeping dog.
>
> Good luck. You're going to need slightly less of it than you think."

### Fragment 003 — "Compact Infrastructure Report, Mid Ring, Final Entry"
> "...the arch expansion was 40% complete when the Unspooling interrupted the Resonance weave. The arch cannot be finished now — the Resonance pattern required to complete the keystone no longer exists in stable form. The arch will remain standing indefinitely. It cannot fall. It also cannot be used for its original purpose.
>
> We are recommending this be documented as a permanent feature.
>
> — Chief Architect Minna Dross, Compact Survey Office"

### Fragment 004 — "Outer Ring survey, pre-Unspooling, classified tier"
> "INCURSION CLASSIFICATION: ACTIVE. Do not record the specifics of what was encountered at survey point 7. The decision has been made to Compact-seal this record pending review.
>
> What I will say for the historians who eventually open this: whatever is in the Outer Ring was not there before the Unspooling. It arrived with the fracture, or shortly after. It has a purpose. We have not been able to determine what the purpose is, only that it is consistent and has been, since the beginning, pointed at the Artifact.
>
> If you are reading this, good luck. I mean that without irony.
>
> — Surveyor Orin Takt, Compact Intelligence Division"

### Fragment 005 — "Genn's own handwriting, found tacked to Sanctuary inner door"
> "To whoever comes through after me:
>
> The fire takes two logs in the morning, one at night. The stew needs the third jar from the left, not the second — the second is something I found and have not identified.
>
> The records on the Artifact are in the chest under the workbench. Read them. Then make your own decision.
>
> If you're reading this because I'm not here: I lasted longer than expected. Don't let that become your benchmark.
>
> — G"

---

## Warden Boss Intro Monologue

*(Displayed as sequential text cards at the Ring 3 boss gate, before combat initiates)*

> "..."
>
> *(The thing at the end of the Outer Ring has no name in the records. The Compact sealed those documents. You know it as the Warden because that's what Genn called it, and Genn calls things what they are.)*
>
> "You have the smell of the Compact on you. Old tools. Old methods. Old hope."
>
> "I was given a purpose. I have executed it for three hundred years. I am very good at my purpose."
>
> "You're going to try anyway. I know. They all do."
>
> *(It moves.)*

---

## Implementation Notes

- `narrative.json` ships as a standalone data file in `game/data/`
- `NarrativeManager.gd` loads on startup as an autoload singleton
- All narrative text is displayed via existing `FlowUI` surfaces — no new scenes required for T8-T11
- Prologue runs once on first launch (gated by `GameState.prologue_seen` flag)
- Ring entry text fires on `RingDirector.ring_entered` signal
- Lore fragments are added to `LootEngine` as a drop type `"lore_fragment"` with an ID
- Warden intro fires at boss gate transition in Ring 3 (which is a T18+ implementation detail — write the data now, hook later)

---

## What This Unlocks

With M17 complete:
- The game has a story with a beginning, middle, and end
- NPCs feel like people, not menus
- Death feels like a setback in a world, not a game over screen
- The Artifact extraction has emotional weight
- The world is specific — Cauldron, the Compact, the Unspooling — not generic fantasy
- Players have reasons to push deeper beyond mechanical reward

Next: M18 — Ring 3 + Warden implementation (combat only; narrative data is ready)
