# M22 — Upgrade Shop Polish + Economy Balance

**Status:** COMPLETE
**Date Authored:** 2026-03-25
**Date Completed:** 2026-03-25
**Author:** Claude Code
**Scope:** Vendor UI polish, economy balancing, flavorful upgrade descriptions, category grouping, purchase feedback

---

## Overview

M22 transforms the vendor from a flat list of stat buttons into a place that feels meaningful. Every upgrade now has an evocative name, a specific description, and an optional Genn lore note. Upgrades are grouped by category (Combat, Survival, Mobility) with visual headers. Purchased upgrades show "Owned" state instead of confusing duplicate buy buttons. After each purchase, Genn reacts with a brief toast line. Economy is rebalanced so silver spending is a real decision at every ring tier.

---

## Deliverables

| # | Task | Status |
|---|------|--------|
| T1 | Audit current shop state (4 upgrades, flat list, generic names, prices 40-60) | DONE |
| T2 | Upgrade descriptions pass — evocative names, flavorful descriptions, lore_notes | DONE |
| T3 | Economy balance pass — minor/major pricing tiers, ring yield verification | DONE |
| T4 | Shop UI category display — Combat/Survival/Mobility headers | DONE |
| T5 | Genn dialogue toast on purchase (2.5s auto-dismiss, non-blocking) | DONE |
| T6 | Already Purchased state — "Owned (MAX)" / "Owned Lv X" with visual dimming | DONE |
| T7 | Test suite (3 files, 42 assertions, all green) | DONE |
| T8 | Milestone summary | DONE |

---

## Economy Balance (T3)

### Before (M21)

| Upgrade | Price |
|---------|-------|
| Iron Will (+20 HP) | 50 |
| Swift Feet (+10 stamina) | 40 |
| Sharp Edge (+15% damage) | 60 |
| Iron Poise (+20 poise) | 45 |

All prices clustered at 40-60. Inner ring clear (72 silver) could buy any upgrade. No meaningful spending decisions.

### After (M22)

| Upgrade | Category | Price | Tier |
|---------|----------|-------|------|
| Iron Constitution (+20 HP) | Survival | 120 | Major |
| Runner's Wrap (+10 stamina) | Mobility | 65 | Minor |
| Honed Edge (+15% damage) | Combat | 130 | Major |
| Steady Nerve (+20 poise) | Survival | 65 | Minor |

### Ring Yield vs Prices

| Ring | Encounters | Min Yield | Affords |
|------|-----------|-----------|---------|
| Inner | 3 | 72 silver | 1 minor (65) |
| Mid | 4 | 144 silver | 1 major (120-130) OR 2 minor (130) |
| Outer | 5 | 265 silver | 2 major (240-260) |

Every purchase is now a decision. Inner ring players must choose which minor upgrade matters most. Mid ring opens up majors but not multiple. Outer ring rewards risk with the ability to stock up.

---

## Upgrade Descriptions (T2)

| ID | Old Name | New Name | Description |
|----|----------|----------|-------------|
| iron_will | Iron Will | Iron Constitution | "Reinforced chest binding. Absorbs 20 extra points of punishment per level." |
| swift_feet | Swift Feet | Runner's Wrap | "Treated ankle bindings. Your lungs last 10 points longer when it matters." |
| sharp_edge | Sharp Edge | Honed Edge | "Weighted grip tape. Your strikes carry 15% more force per level." |
| iron_poise | Iron Poise | Steady Nerve | "Dampening weave for your boots. Holds you upright when they try to break your stance." |

Each upgrade also has a `lore_note` field with a Genn-voice one-liner (not currently displayed in UI but available for future tooltip/detail view).

---

## Shop UI Changes (T4, T5, T6)

- **Category grouping**: Upgrades grouped under "COMBAT", "SURVIVAL", "MOBILITY" headers with accent color
- **Owned state**: Maxed upgrades show "Owned (MAX)" with dimmed label; partially purchased show "Owned Lv X — Upgrade (cost)"; owned labels tinted green, maxed tinted gray
- **Purchase feedback**: `show_vendor_purchase_toast()` displays Genn's reaction as a bottom-anchored label, auto-dismisses after 2.5s, does not block UI interaction
- **Margin/layout**: Vendor panel now has proper margins for readability

---

## Test Suite

| Test File | Assertions | Coverage |
|-----------|------------|----------|
| `upgrade_data_test.gd` | 22 | Name, description, category, price, mechanical fields for all 4 upgrades + category diversity |
| `economy_balance_test.gd` | 8 | Ring yields vs prices: inner >= cheapest, mid >= expensive, outer >= 2x expensive, scarcity check |
| `shop_ui_test.gd` | 12 | Owned/unpurchased/maxed button text, disabled states, category data, toast wiring, UI integration |
| **Total** | **42** | |

---

## Files Changed

- `game/data/vendor_upgrades.json` — new names, descriptions, lore_notes, categories, rebalanced prices
- `game/scripts/ui/flow_ui.gd` — category-grouped vendor panel, owned state display, vendor purchase toast
- `game/scripts/main.gd` — wire Genn purchase toast after vendor buy
- `game/scripts/tests/m22/upgrade_data_test.gd` — new
- `game/scripts/tests/m22/economy_balance_test.gd` — new
- `game/scripts/tests/m22/shop_ui_test.gd` — new
- `scripts/ci/headless_tests.sh` — M22 test entries

---

## What This Unlocks

- **M23+**: Tooltip/detail view can display lore_notes
- **M23+**: New upgrades can be added with category assignment and the UI auto-groups them
- **M23+**: Economy framework supports adding ring-specific shop inventory or upgrade tiers
