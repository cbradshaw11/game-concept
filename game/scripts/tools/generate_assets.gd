@tool
extends EditorScript
## Run this in the Godot editor (Scene > Run Script) to verify assets exist.
## Actual PNG generation is done by scripts/tools/generate_placeholder_assets.py

func _run() -> void:
	var asset_paths := [
		"res://assets/sprites/player.png",
		"res://assets/sprites/enemy_grunt.png",
		"res://assets/sprites/enemy_defender.png",
		"res://assets/sprites/enemy_ranged.png",
		"res://assets/backgrounds/inner.png",
		"res://assets/backgrounds/mid.png",
		"res://assets/backgrounds/outer.png",
	]
	for path in asset_paths:
		if ResourceLoader.exists(path):
			print("[OK] ", path)
		else:
			push_warning("[MISSING] " + path)
