extends Node
# class_name omitted — autoload singleton accessed via "AudioManager" globally

## AudioManager — central audio system for SFX and music.
## All other scripts call AudioManager.play_sfx("hit_player") etc.
## Missing audio files fail silently with a warning — no crashes.

# ── SFX Registry ─────────────────────────────────────────────────────────────

const SFX_REGISTRY := {
	"hit_player": "res://audio/sfx/hit_player.wav",
	"hit_enemy": "res://audio/sfx/hit_enemy.wav",
	"enemy_death": "res://audio/sfx/enemy_death.wav",
	"player_death": "res://audio/sfx/player_death.wav",
	"dodge": "res://audio/sfx/dodge.wav",
	"guard_break": "res://audio/sfx/guard_break.wav",
	"poise_break": "res://audio/sfx/poise_break.wav",
	"warden_phase": "res://audio/sfx/warden_phase.wav",
	"extraction": "res://audio/sfx/extraction.wav",
	"artifact_pickup": "res://audio/sfx/artifact_pickup.wav",
	"ui_confirm": "res://audio/sfx/ui_confirm.wav",
	"ui_cancel": "res://audio/sfx/ui_cancel.wav",
	"upgrade_purchase": "res://audio/sfx/upgrade_purchase.wav",
	"modifier_accept": "res://audio/sfx/modifier_accept.wav",
	"lore_fragment": "res://audio/sfx/lore_fragment.wav",
	"shard_earn": "res://audio/sfx/shard_earn.wav",
	"ring_enter": "res://audio/sfx/ring_enter.wav",
	"swing": "res://audio/sfx/swing.wav",
	"heavy_swing": "res://audio/sfx/heavy_swing.wav",
	"swing_blade": "res://audio/sfx/swing_blade.wav",
	"swing_dagger": "res://audio/sfx/swing_dagger.wav",
	"swing_polearm": "res://audio/sfx/swing_polearm.wav",
	"swing_hammer": "res://audio/sfx/swing_hammer.wav",
	"swing_bow": "res://audio/sfx/swing_bow.wav",
	"swing_staff": "res://audio/sfx/swing_staff.wav",
	"swing_greatsword": "res://audio/sfx/swing_greatsword.wav",
	"swing_crossbow": "res://audio/sfx/swing_crossbow.wav",
	"swing_orb": "res://audio/sfx/swing_orb.wav",
	"heavy_swing_blade": "res://audio/sfx/heavy_swing_blade.wav",
	"heavy_swing_dagger": "res://audio/sfx/heavy_swing_dagger.wav",
	"heavy_swing_polearm": "res://audio/sfx/heavy_swing_polearm.wav",
	"heavy_swing_hammer": "res://audio/sfx/heavy_swing_hammer.wav",
	"heavy_swing_bow": "res://audio/sfx/heavy_swing_bow.wav",
	"heavy_swing_staff": "res://audio/sfx/heavy_swing_staff.wav",
	"heavy_swing_greatsword": "res://audio/sfx/heavy_swing_greatsword.wav",
	"heavy_swing_crossbow": "res://audio/sfx/heavy_swing_crossbow.wav",
	"heavy_swing_orb": "res://audio/sfx/heavy_swing_orb.wav",
}

# ── Music Registry ───────────────────────────────────────────────────────────

const MUSIC_REGISTRY := {
	"sanctuary": "res://audio/music/sanctuary.ogg",
	"combat_inner": "res://audio/music/combat_inner.ogg",
	"combat_mid": "res://audio/music/combat_mid.ogg",
	"combat_outer": "res://audio/music/combat_outer.ogg",
	"warden": "res://audio/music/warden.ogg",
	"title": "res://audio/music/title.ogg",
	"victory": "res://audio/music/victory.ogg",
}

# ── Internal State ───────────────────────────────────────────────────────────

var _sfx_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _current_music_id: String = ""
var _sfx_cache: Dictionary = {}  # path -> AudioStream
var _music_cache: Dictionary = {}  # path -> AudioStream
var _fade_tween: Tween = null

func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = &"SFX"
	add_child(_sfx_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	_music_player.volume_db = 0.0
	add_child(_music_player)

	# Ensure audio buses exist (Master is always bus 0)
	_ensure_bus("SFX")
	_ensure_bus("Music")

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")

# ── SFX ──────────────────────────────────────────────────────────────────────

func play_sfx(sound_id: String) -> void:
	var path: String = SFX_REGISTRY.get(sound_id, "")
	if path == "":
		push_warning("AudioManager: unknown sfx id '%s'" % sound_id)
		return
	var stream := _load_cached(path, _sfx_cache)
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()

# ── Legacy convenience helpers (used by existing code) ───────────────────────

func play_attack() -> void:    play_sfx("hit_enemy")
func play_hit() -> void:       play_sfx("hit_player")
func play_dodge() -> void:     play_sfx("dodge")
func play_guard() -> void:     play_sfx("guard_break")
func play_death() -> void:     play_sfx("enemy_death")
func play_victory() -> void:   play_sfx("extraction")
func play_ui_click() -> void:  play_sfx("ui_confirm")

# ── Music ────────────────────────────────────────────────────────────────────

func play_music(track_id: String, fade_in: float = 0.5) -> void:
	if track_id == _current_music_id:
		return
	_current_music_id = track_id
	var path: String = MUSIC_REGISTRY.get(track_id, "")
	if path == "":
		push_warning("AudioManager: unknown music id '%s'" % track_id)
		return
	var stream := _load_cached(path, _music_cache)
	if stream == null:
		return
	_kill_fade()
	_music_player.stream = stream
	if fade_in > 0.0:
		_music_player.volume_db = -40.0
		_music_player.play()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_music_player, "volume_db", 0.0, fade_in)
	else:
		_music_player.volume_db = 0.0
		_music_player.play()

func stop_music(fade_out: float = 1.0) -> void:
	if not _music_player.playing:
		_current_music_id = ""
		return
	_kill_fade()
	if fade_out > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_music_player, "volume_db", -40.0, fade_out)
		_fade_tween.tween_callback(_music_player.stop)
		_fade_tween.tween_callback(func(): _current_music_id = "")
	else:
		_music_player.stop()
		_current_music_id = ""

## Legacy helpers used by existing combat_arena / flow_ui code
func play_combat_music() -> void:
	play_music("combat_inner")

func play_sanctuary_music() -> void:
	play_music("sanctuary")

# ── Volume ───────────────────────────────────────────────────────────────────

func set_sfx_volume(db: float) -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)

func set_music_volume(db: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)

func get_sfx_volume() -> float:
	var idx := AudioServer.get_bus_index("SFX")
	return AudioServer.get_bus_volume_db(idx) if idx != -1 else 0.0

func get_music_volume() -> float:
	var idx := AudioServer.get_bus_index("Music")
	return AudioServer.get_bus_volume_db(idx) if idx != -1 else 0.0

# ── Queries ──────────────────────────────────────────────────────────────────

func get_sfx_ids() -> Array:
	return SFX_REGISTRY.keys()

func get_music_ids() -> Array:
	return MUSIC_REGISTRY.keys()

func is_music_playing() -> bool:
	return _music_player.playing

func get_current_music_id() -> String:
	return _current_music_id

# ── Internal ─────────────────────────────────────────────────────────────────

func _load_cached(path: String, cache: Dictionary) -> AudioStream:
	if cache.has(path):
		return cache[path]
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: file not found: %s" % path)
		return null
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("AudioManager: failed to load: %s" % path)
		return null
	cache[path] = stream
	return stream

func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
