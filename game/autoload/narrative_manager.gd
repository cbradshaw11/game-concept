extends Node
# class_name omitted — autoload singleton accessed via "NarrativeManager" globally

## NarrativeManager — M17 Narrative Layer
## Loads narrative.json and exposes the narrative text API for all game surfaces.
## Registered as an autoload in project.godot.

const NARRATIVE_PATH := "res://data/narrative.json"

var _data: Dictionary = {}
var _loaded: bool = false

func _ready() -> void:
	_load_data()

func _load_data() -> void:
	var file := FileAccess.open(NARRATIVE_PATH, FileAccess.READ)
	if file == null:
		push_error("NarrativeManager: could not open %s" % NARRATIVE_PATH)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("NarrativeManager: JSON parse error in %s (line %d): %s" % [
			NARRATIVE_PATH, json.get_error_line(), json.get_error_message()
		])
		return
	var parsed: Variant = json.get_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("NarrativeManager: root of narrative.json is not a Dictionary")
		return
	_data = parsed
	_loaded = true

# Returns true if narrative data was successfully loaded.
func is_loaded() -> bool:
	return _loaded

# ── Prologue ──────────────────────────────────────────────────────────────────

## Returns the prologue as an Array of beat Dictionaries.
## Each beat has: id, beat (int), type, lines (Array), and optionally choices.
func get_prologue() -> Array:
	return _data.get("prologue", [])

# ── Ring text ─────────────────────────────────────────────────────────────────

## Returns a single narrative string for a ring event.
## ring_id: "sanctuary" | "inner" | "mid" | "outer"
## event_type: "entry" | "extraction" | "death" | "warden_gate"
## Returns "" if no text is available.
func get_ring_text(ring_id: String, event_type: String) -> String:
	match event_type:
		"entry":
			return _get_entry_text(ring_id)
		"extraction":
			var flavor: Dictionary = _data.get("extraction_flavor", {})
			return _random_line(flavor.get(ring_id, []))
		"death":
			var flavor: Dictionary = _data.get("death_flavor", {})
			return _random_line(flavor.get(ring_id, []))
		"warden_gate":
			return _random_line(get_warden_intro())
	push_warning("NarrativeManager.get_ring_text: unknown event_type '%s'" % event_type)
	return ""

func _get_entry_text(ring_id: String) -> String:
	var ring_entry: Dictionary = _data.get("ring_entry", {})
	var ring_data: Dictionary = ring_entry.get(ring_id, {})
	if ring_data.is_empty():
		return ""
	# Sanctuary uses "return" key (you always return to it)
	if ring_id == "sanctuary":
		return _random_line(ring_data.get("return", []))
	# Other rings: first visit vs repeat
	var gs := get_node_or_null("/root/GameState")
	var has_extracted := false
	if gs != null:
		has_extracted = bool(gs.call("has_extracted_from", ring_id))
	var is_first := not has_extracted
	var key := "first" if is_first else "repeat"
	var lines: Array = ring_data.get(key, [])
	if lines.is_empty():
		# Fall back to the other key if the preferred one is empty
		var fallback_key := "repeat" if is_first else "first"
		lines = ring_data.get(fallback_key, [])
	return _random_line(lines)

# ── NPC dialogue ─────────────────────────────────────────────────────────────

## Returns a single NPC dialogue line chosen based on current game context.
## npc_id: "genn_vendor" (and future NPC ids)
## Returns "" if no line is available.
func get_npc_line(npc_id: String) -> String:
	var npc_dialogue: Dictionary = _data.get("npc_dialogue", {})
	var npc: Dictionary = npc_dialogue.get(npc_id, {})
	if npc.is_empty():
		return ""
	return _select_npc_line(npc_id, npc)

func _select_npc_line(npc_id: String, npc: Dictionary) -> String:
	if npc_id == "genn_vendor":
		return _genn_vendor_line(npc)
	# Generic fallback: flatten all pools and pick random
	var all_lines: Array = []
	for key in npc:
		var pool: Variant = npc.get(key)
		if typeof(pool) == TYPE_ARRAY:
			all_lines.append_array(pool)
	return _random_line(all_lines)

func _genn_vendor_line(npc: Dictionary) -> String:
	# Determine context from GameState (via node lookup — avoids static parse errors in tests)
	var gs := get_node_or_null("/root/GameState")
	var outer_unlocked := false
	var mid_unlocked := false
	var has_died := false
	if gs != null:
		outer_unlocked = bool(gs.call("has_extracted_from", "mid"))
		mid_unlocked = bool(gs.call("has_extracted_from", "inner"))
		var history: Array = gs.get("run_history") if gs.get("run_history") != null else []
		if not history.is_empty():
			has_died = not bool(history[-1].get("extracted", true))

	var pool_key := "greeting"
	if outer_unlocked:
		pool_key = "after_outer_unlock"
	elif mid_unlocked:
		pool_key = "after_mid_unlock"
	elif has_died:
		pool_key = "after_first_death"

	var lines: Array = npc.get(pool_key, [])
	if lines.is_empty():
		lines = npc.get("greeting", [])
	return _random_line(lines)

## Returns on_purchase or on_browse_no_purchase vendor dialogue for Genn.
## context: "purchase" | "browse"
func get_genn_vendor_reaction(context: String) -> String:
	var npc_dialogue: Dictionary = _data.get("npc_dialogue", {})
	var npc: Dictionary = npc_dialogue.get("genn_vendor", {})
	if npc.is_empty():
		return ""
	var key := "on_purchase" if context == "purchase" else "on_browse_no_purchase"
	return _random_line(npc.get(key, []))

# ── Lore fragments ───────────────────────────────────────────────────────────

## Returns a lore fragment Dictionary by ID, or a random one if id == "".
## Keys: id, title, author, ring, text
## Returns {} if not found.
func get_lore_fragment(id: String = "") -> Dictionary:
	var fragments: Array = _data.get("lore_fragments", [])
	if fragments.is_empty():
		return {}
	if id == "":
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		return fragments[rng.randi_range(0, fragments.size() - 1)]
	for fragment in fragments:
		if str(fragment.get("id", "")) == id:
			return fragment
	return {}

## Returns all lore fragment IDs.
func get_all_lore_fragment_ids() -> Array:
	var ids: Array = []
	for fragment in _data.get("lore_fragments", []):
		ids.append(str(fragment.get("id", "")))
	return ids

# ── Warden intro ─────────────────────────────────────────────────────────────

## Returns the Warden boss intro monologue as an Array of Strings.
## Displayed sequentially at the Ring 3 boss gate (T18+ hook).
func get_warden_intro() -> Array:
	var warden: Dictionary = _data.get("warden_intro", {})
	return warden.get("lines", [])

# ── Internal ─────────────────────────────────────────────────────────────────

func _random_line(lines: Array) -> String:
	if lines.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return str(lines[rng.randi_range(0, lines.size() - 1)])
