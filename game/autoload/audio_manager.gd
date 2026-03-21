extends Node
# class_name omitted — autoload singleton accessed via "AudioManager" globally

## AudioManager — plays SFX and ambient music throughout the game.
## Loaded as an autoload. All other scripts call AudioManager.play_sfx() etc.

const SFX_DIR := "res://assets/audio/"
const MUSIC_DIR := "res://assets/audio/"

var _sfx_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _current_music: String = ""

# Preload SFX streams lazily (cache after first load)
var _sfx_cache: Dictionary = {}

func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -6.0
	add_child(_music_player)

# ── SFX ──────────────────────────────────────────────────────────────────────

func play_sfx(name: String) -> void:
	var stream := _get_sfx_stream(name)
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()

func _get_sfx_stream(name: String) -> AudioStream:
	if _sfx_cache.has(name):
		return _sfx_cache[name]
	var path := SFX_DIR + name
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: sfx not found: %s" % path)
		return null
	var stream: AudioStream = load(path)
	_sfx_cache[name] = stream
	return stream

# Convenience helpers
func play_attack() -> void:   play_sfx("sfx_attack.wav")
func play_hit() -> void:      play_sfx("sfx_hit.wav")
func play_dodge() -> void:    play_sfx("sfx_dodge.wav")
func play_guard() -> void:    play_sfx("sfx_guard.wav")
func play_death() -> void:    play_sfx("sfx_death.wav")
func play_victory() -> void:  play_sfx("sfx_victory.wav")
func play_ui_click() -> void: play_sfx("sfx_ui_click.wav")

# ── Music ─────────────────────────────────────────────────────────────────────

func play_music(filename: String, loop: bool = true) -> void:
	if _current_music == filename:
		return
	_current_music = filename
	var path := MUSIC_DIR + filename
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: music not found: %s" % path)
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	_music_player.stream = stream
	_music_player.play()

func play_combat_music() -> void:
	play_music("music_combat.wav")

func play_sanctuary_music() -> void:
	play_music("music_sanctuary.wav")

func stop_music() -> void:
	_current_music = ""
	_music_player.stop()

func set_music_volume(db: float) -> void:
	_music_player.volume_db = db

func set_sfx_volume(db: float) -> void:
	_sfx_player.volume_db = db
