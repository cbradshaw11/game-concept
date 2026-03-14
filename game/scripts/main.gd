extends Node

const RingDirector = preload("res://scripts/systems/ring_director.gd")
const RewardSystem = preload("res://scripts/systems/reward_system.gd")
const SaveSystem = preload("res://scripts/systems/save_system.gd")
const CombatArenaScene = preload("res://scenes/combat/combat_arena.tscn")
const ContractSystem = preload("res://scripts/systems/contract_system.gd")
const PrologueScene = preload("res://scenes/ui/prologue.tscn")
const TitleScreenScene = preload("res://scenes/ui/title_screen.tscn")
const VictoryScene = preload("res://scenes/ui/victory.tscn")

@onready var flow_ui: FlowUI = $FlowUI

var ring_director := RingDirector.new()
var reward_system := RewardSystem.new()
var contract_system := ContractSystem.new()
var active_encounter: Dictionary = {}
var combat_arena: CombatArena = null
var _prologue_instance: CanvasLayer = null
var _title_screen_instance: CanvasLayer = null
var _victory_instance: CanvasLayer = null

var _music_player: AudioStreamPlayer = null
var _ambience_player: AudioStreamPlayer = null
var _music_tween: Tween = null
var _encounter_resolved: bool = false

var _combat_track_map: Dictionary = {
	"inner": "res://audio/music_combat_inner.wav",
	"mid": "res://audio/music_combat_mid.wav",
	"outer": "res://audio/music_combat_outer.wav",
}

func _get_combat_music_path(ring_id: String) -> String:
	var ring_path: String = _combat_track_map.get(ring_id, "res://audio/music_combat.wav")
	if ResourceLoader.exists(ring_path):
		return ring_path
	return "res://audio/music_combat.wav"  # fallback until ring assets exist -- TODO M13: add music_combat_inner/mid/outer.wav

func _ready() -> void:
	print("The Long Walk MVP Slice 1 booted")
	_setup_audio_players()
	_connect_ui()
	_connect_state()
	_initialize_loadouts()
	_show_title_screen()
	_play_music("music_sanctuary")
	_play_ambience("ambient_ring")

func _setup_audio_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = "Music"
	add_child(_ambience_player)

func _play_music(track_name: String, fade_in: float = 0.5) -> void:
	var path := "res://audio/%s.wav" % track_name
	if not ResourceLoader.exists(path):
		push_warning("Music track not found: " + path)
		return
	var stream = load(path)
	if stream == null:
		push_warning("Failed to load music track: " + path)
		return
	_music_player.stream = stream
	_music_player.volume_db = -80.0
	_music_player.play()
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_in)

func _play_music_from_path(path: String, fade_in: float = 0.5) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Music track not found: " + path)
		return
	var stream = load(path)
	if stream == null:
		push_warning("Failed to load music track: " + path)
		return
	_music_player.stream = stream
	_music_player.volume_db = -80.0
	_music_player.play()
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_in)

func _stop_music(fade_out: float = 0.5) -> void:
	if not _music_player.playing:
		return
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_out)
	_music_tween.tween_callback(_music_player.stop)

func _play_ambience(track_name: String) -> void:
	var path := "res://audio/%s.wav" % track_name
	if not ResourceLoader.exists(path):
		push_warning("Ambience track not found: " + path)
		return
	var stream = load(path)
	if stream == null:
		return
	_ambience_player.stream = stream
	_ambience_player.volume_db = -6.0
	_ambience_player.play()

func _stop_ambience() -> void:
	_ambience_player.stop()

func _show_title_screen() -> void:
	if is_instance_valid(_title_screen_instance):
		return
	_title_screen_instance = TitleScreenScene.instantiate() as CanvasLayer
	add_child(_title_screen_instance)
	_title_screen_instance.new_game_requested.connect(_on_title_new_game)
	_title_screen_instance.continue_requested.connect(_on_title_continue)

func _on_title_new_game() -> void:
	GameState.reset_for_new_game()
	_dismiss_title_screen()
	# New game always shows the prologue
	_show_prologue()

func _on_title_continue() -> void:
	_load_save_state()
	_dismiss_title_screen()
	if not GameState.prologue_seen:
		_show_prologue()
	else:
		flow_ui.on_idle_ready()

func _dismiss_title_screen() -> void:
	if is_instance_valid(_title_screen_instance):
		_title_screen_instance.queue_free()
		_title_screen_instance = null

func _show_prologue() -> void:
	_prologue_instance = PrologueScene.instantiate() as CanvasLayer
	add_child(_prologue_instance)
	_prologue_instance.prologue_finished.connect(_on_prologue_finished)

func _on_prologue_finished() -> void:
	GameState.prologue_seen = true
	_save_state()
	if is_instance_valid(_prologue_instance):
		_prologue_instance.queue_free()
		_prologue_instance = null
	flow_ui.on_idle_ready()

func _connect_ui() -> void:
	flow_ui.start_run_pressed.connect(_on_start_run_pressed)
	flow_ui.resolve_encounter_pressed.connect(_on_resolve_encounter_pressed)
	flow_ui.extract_pressed.connect(_on_extract_pressed)
	flow_ui.die_pressed.connect(_on_die_pressed)
	flow_ui.loadout_selected.connect(_on_loadout_selected)
	flow_ui.descend_warden_pressed.connect(_on_descend_warden_pressed)
	flow_ui.upgrade_selected.connect(_on_upgrade_selected)
	flow_ui.back_to_menu_requested.connect(_on_back_to_menu_requested)

func _on_back_to_menu_requested() -> void:
	_show_title_screen()

func _connect_state() -> void:
	GameState.run_started.connect(flow_ui.on_run_started)
	GameState.encounter_completed.connect(flow_ui.on_encounter_resolved)
	GameState.extracted.connect(flow_ui.on_extracted)
	GameState.player_died.connect(_on_player_died)

func _on_start_run_pressed() -> void:
	var seed := Time.get_unix_time_from_system()
	GameState.start_run(int(seed), GameState.current_ring)
	var ring_data: Dictionary = {}
	for r in DataStore.rings.get("rings", []):
		if r.get("id") == GameState.current_ring:
			ring_data = r
			break
	var contract_target: int = ring_data.get("contract_target", 3)
	var contract := contract_system.start_contract("ring_clearance", GameState.current_ring, contract_target)
	flow_ui.on_objective_started(contract)
	_encounter_resolved = false
	active_encounter = ring_director.generate_encounter(
		int(seed),
		GameState.current_ring,
		DataStore.enemies,
		DataStore.encounter_templates
	)
	_ensure_combat_arena()
	combat_arena.set_context(GameState.current_ring, int(seed), int(active_encounter.get("enemy_count", 1)), active_encounter.get("enemies", []))
	combat_arena.set_arena_active(true)
	# Reset player to base stats, then apply permanent upgrades, per-run upgrades, modifiers.
	# reset_for_run() prevents stat accumulation on the reused player node across runs.
	if is_instance_valid(combat_arena) and is_instance_valid(combat_arena.player):
		combat_arena.player.reset_for_run()
		for upgrade in GameState.permanent_upgrades:
			combat_arena.player.apply_upgrade(upgrade)
		# Apply permanent_xp prestige purchases
		if "veteran_spirit" in GameState.permanent_purchases:
			var _vs_value: int = 20
			for _si in DataStore.shop_items.get("items", []):
				if _si.get("id", "") == "veteran_spirit":
					_vs_value = int(_si.get("value", 20))
					break
			combat_arena.player.apply_upgrade({"stat": "max_stamina", "modifier_type": "add", "value": _vs_value})
		for upgrade in GameState.active_upgrades:
			combat_arena.player.apply_upgrade(upgrade)
		for modifier in GameState.active_modifiers:
			combat_arena.player.apply_modifier(modifier)
	flow_ui.set_current_loadout(GameState.selected_weapon_id)
	# Switch to combat music when run starts: fade out sanctuary, then fade in ring-specific combat track
	var _combat_path := _get_combat_music_path(GameState.current_ring)
	_stop_music(0.3)
	_music_tween.tween_callback(func() -> void: _play_music_from_path(_combat_path))
	_stop_ambience()

func _on_resolve_encounter_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	if active_encounter.get("enemies", []).is_empty():
		return
	if _encounter_resolved:
		return
	_encounter_resolved = true

	var rewards := reward_system.calculate_rewards(
		GameState.current_ring,
		DataStore.rings,
		int(active_encounter.get("enemy_count", 1))
	)
	var loot_bonus: int = GameState.get_loot_per_encounter_bonus()
	var is_first_encounter := GameState.encounters_cleared == 0
	for m in GameState.active_modifiers:
		if m.get("id") == "scavenger_instinct" and is_first_encounter:
			loot_bonus += int(rewards.get("loot", 0))
			break
	GameState.add_unbanked(int(rewards["xp"]), int(rewards["loot"]) + loot_bonus)
	var contract := contract_system.record_encounter_completed()
	flow_ui.on_objective_progress(contract)
	active_encounter = {}

func _on_extract_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	if not contract_system.can_extract():
		flow_ui.on_extract_blocked(contract_system.get_contract())
		return
	GameState.extract()
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	contract_system.reset()
	_save_state()
	# Return to sanctuary music after extraction
	_play_music("music_sanctuary")
	_play_ambience("ambient_ring")

func _on_die_pressed() -> void:
	if GameState.current_ring == "sanctuary":
		return
	var xp_at_risk: int = GameState.unbanked_xp
	var loot_at_risk: int = GameState.unbanked_loot
	var ring_at_death: String = GameState.current_ring
	GameState.die_in_run()
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	contract_system.fail_active_contract()
	# Show objective failure before death panel so contract fail state is visible
	flow_ui.on_objective_failed(contract_system.get_contract())
	flow_ui.on_died(xp_at_risk, loot_at_risk, ring_at_death)
	_save_state()
	# Return to sanctuary music after dying
	_play_music("music_sanctuary")
	_play_ambience("ambient_ring")

func _on_player_died() -> void:
	# Signal handler for GameState.player_died -- audio/arena teardown only.
	# Death panel display is handled by the explicit die paths (_on_die_pressed,
	# _on_combat_player_died) so that on_objective_failed runs before on_died.
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	# Return to sanctuary music after player death
	_play_music("music_sanctuary")
	_play_ambience("ambient_ring")

func _on_combat_player_died() -> void:
	if GameState.current_ring == "sanctuary":
		return
	var xp_at_risk: int = GameState.unbanked_xp
	var loot_at_risk: int = GameState.unbanked_loot
	var ring_at_death: String = GameState.current_ring
	GameState.die_in_run()
	contract_system.fail_active_contract()
	# Show objective failure before death panel so contract fail state is visible
	flow_ui.on_objective_failed(contract_system.get_contract())
	flow_ui.on_died(xp_at_risk, loot_at_risk, ring_at_death)
	_save_state()

func _ensure_combat_arena() -> void:
	if combat_arena != null:
		return
	combat_arena = CombatArenaScene.instantiate() as CombatArena
	add_child(combat_arena)
	combat_arena.attack_hook_triggered.connect(_on_attack_hook_triggered)
	combat_arena.dodge_hook_triggered.connect(_on_dodge_hook_triggered)
	combat_arena.guard_hook_changed.connect(_on_guard_hook_changed)
	combat_arena.encounter_cleared.connect(_on_encounter_cleared)
	combat_arena.boss_encounter_cleared.connect(_on_warden_defeated)
	combat_arena.player_died.connect(_on_combat_player_died)

func _on_attack_hook_triggered() -> void:
	print("Combat hook: attack")

func _on_dodge_hook_triggered() -> void:
	print("Combat hook: dodge")

func _on_guard_hook_changed(is_guarding: bool) -> void:
	print("Combat hook: guard=%s" % is_guarding)

func _on_encounter_cleared(enemy_count: int) -> void:
	print("Combat hook: encounter cleared (%d enemies)" % enemy_count)
	_on_resolve_encounter_pressed()

func _on_descend_warden_pressed() -> void:
	_ensure_combat_arena()
	combat_arena.set_arena_active(true)
	combat_arena.start_boss_encounter("outer_warden")
	# Warden encounter: crossfade to boss music
	_play_music("music_warden")

func _on_warden_defeated() -> void:
	GameState.warden_defeated = true
	GameState.game_completed = true
	if combat_arena != null:
		combat_arena.set_arena_active(false)
	# Bank any unbanked XP/loot from the warden fight before recording the run
	GameState.banked_xp += GameState.unbanked_xp
	GameState.banked_loot += GameState.unbanked_loot
	GameState.unbanked_xp = 0
	GameState.unbanked_loot = 0
	GameState.record_warden_defeated()
	_save_state()
	# Show victory screen instead of going directly to credits
	if is_instance_valid(_victory_instance):
		return
	_victory_instance = VictoryScene.instantiate() as CanvasLayer
	add_child(_victory_instance)
	# Call populate deferred so @onready vars on victory.gd are initialized by _ready() first
	_victory_instance.populate.call_deferred(
		GameState.rings_cleared.size(),
		GameState.banked_loot,
		GameState.banked_xp,
		GameState.active_seed
	)
	_victory_instance.new_journey_requested.connect(_on_victory_new_journey)
	_victory_instance.return_to_menu_requested.connect(_on_victory_return_to_menu)
	_victory_instance.view_credits_requested.connect(_on_victory_view_credits)
	_play_music("music_sanctuary")
	_play_ambience("ambient_ring")

func _on_victory_new_journey() -> void:
	if is_instance_valid(_victory_instance):
		_victory_instance.queue_free()
		_victory_instance = null
	GameState.reset_for_new_game()
	flow_ui.on_idle_ready()

func _on_victory_return_to_menu() -> void:
	if is_instance_valid(_victory_instance):
		_victory_instance.queue_free()
		_victory_instance = null
	_show_title_screen()

func _on_victory_view_credits() -> void:
	if is_instance_valid(_victory_instance):
		_victory_instance.queue_free()
		_victory_instance = null
	flow_ui.show_credits()

func _initialize_loadouts() -> void:
	var weapons: Array = DataStore.weapons.get("weapons", [])
	if weapons.size() > 0:
		GameState.selected_weapon_id = str(weapons[0].get("id", GameState.selected_weapon_id))
	flow_ui.set_available_loadouts(weapons)
	flow_ui.set_current_loadout(GameState.selected_weapon_id)

func _on_upgrade_selected(upgrade: Dictionary) -> void:
	if is_instance_valid(combat_arena) and is_instance_valid(combat_arena.player):
		combat_arena.player.apply_upgrade(upgrade)

func _on_loadout_selected(weapon_id: String) -> void:
	GameState.selected_weapon_id = weapon_id
	flow_ui.set_current_loadout(GameState.selected_weapon_id)
	if is_instance_valid(combat_arena) and is_instance_valid(combat_arena.player):
		combat_arena.player.reload_weapon_stats()

func _load_save_state() -> void:
	var state := SaveSystem.load_state(GameState.default_save_state())
	GameState.apply_save_state(state)

func _save_state() -> void:
	SaveSystem.save_state(GameState.to_save_state())
