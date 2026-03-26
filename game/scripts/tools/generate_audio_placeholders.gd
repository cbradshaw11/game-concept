## Generate minimal placeholder audio files for the M28 audio system.
## Run headless: godot4 --headless --path game -s res://scripts/tools/generate_audio_placeholders.gd
extends SceneTree

const SFX_FILES := [
	"res://audio/sfx/hit_player.wav",
	"res://audio/sfx/hit_enemy.wav",
	"res://audio/sfx/enemy_death.wav",
	"res://audio/sfx/player_death.wav",
	"res://audio/sfx/dodge.wav",
	"res://audio/sfx/guard_break.wav",
	"res://audio/sfx/poise_break.wav",
	"res://audio/sfx/warden_phase.wav",
	"res://audio/sfx/extraction.wav",
	"res://audio/sfx/artifact_pickup.wav",
	"res://audio/sfx/ui_confirm.wav",
	"res://audio/sfx/ui_cancel.wav",
	"res://audio/sfx/upgrade_purchase.wav",
	"res://audio/sfx/modifier_accept.wav",
	"res://audio/sfx/lore_fragment.wav",
	"res://audio/sfx/shard_earn.wav",
	"res://audio/sfx/ring_enter.wav",
]

const MUSIC_FILES := [
	"res://audio/music/sanctuary.ogg",
	"res://audio/music/combat_inner.ogg",
	"res://audio/music/combat_mid.ogg",
	"res://audio/music/combat_outer.ogg",
	"res://audio/music/warden.ogg",
	"res://audio/music/title.ogg",
	"res://audio/music/victory.ogg",
]

func _initialize() -> void:
	var created := 0
	var skipped := 0

	for path in SFX_FILES:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			skipped += 1
			continue
		_write_minimal_wav(abs_path)
		created += 1

	for path in MUSIC_FILES:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			skipped += 1
			continue
		_write_minimal_ogg(abs_path)
		created += 1

	print("Audio placeholders: %d created, %d skipped (already exist)" % [created, skipped])
	quit()

func _write_minimal_wav(abs_path: String) -> void:
	## Write a valid 44-byte WAV header with 0 audio samples (silence).
	## Format: PCM 16-bit mono 44100 Hz, data chunk size = 0.
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write: %s" % abs_path)
		return
	# RIFF header
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(36)  # file size - 8 (header only, no data)
	f.store_buffer("WAVE".to_ascii_buffer())
	# fmt sub-chunk
	f.store_buffer("fmt ".to_ascii_buffer())
	f.store_32(16)   # sub-chunk size
	f.store_16(1)    # PCM format
	f.store_16(1)    # mono
	f.store_32(44100)  # sample rate
	f.store_32(88200)  # byte rate (44100 * 1 * 2)
	f.store_16(2)    # block align (channels * bits/8)
	f.store_16(16)   # bits per sample
	# data sub-chunk
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(0)    # data size = 0 bytes
	f.close()

func _write_minimal_ogg(abs_path: String) -> void:
	## Write a minimal OGG Vorbis file.
	## This is a valid OGG container with an empty page — enough to not crash
	## Godot's resource loader (it will just play silence / zero-length).
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write: %s" % abs_path)
		return
	# OGG page header (minimal valid page)
	f.store_buffer("OggS".to_ascii_buffer())  # capture pattern
	f.store_8(0)    # version
	f.store_8(6)    # header type: BOS + EOS (first and last page)
	f.store_64(0)   # granule position
	f.store_32(1)   # serial number
	f.store_32(0)   # page sequence number
	f.store_32(0)   # CRC (invalid but won't crash loader)
	f.store_8(0)    # number of segments = 0
	f.close()
