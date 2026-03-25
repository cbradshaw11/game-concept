## screenshot_capture.gd
## Headless screenshot tool for visual regression / inspection.
## Usage: godot4 --headless --path game -s res://scripts/tools/screenshot_capture.gd
##
## Boots the game to each major screen, captures a screenshot, saves to /tmp/screenshots/.
## Designed for autonomous visual review by shadowBot.

extends SceneTree

const SAVE_DIR := "/tmp/game_screenshots/"
const SCREENS := [
	{ "name": "main",        "scene": "res://scenes/main.tscn" },
	{ "name": "flow_ui",     "scene": "res://scenes/ui/flow_ui.tscn" },
	{ "name": "combat_arena","scene": "res://scenes/combat/combat_arena.tscn" },
]

func _initialize() -> void:
	# Ensure output directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

	var captured := 0
	var failed := 0

	for screen in SCREENS:
		var scene_path: String = screen["scene"]
		var name: String = screen["name"]

		if not FileAccess.file_exists(scene_path):
			print("SKIP: %s (scene not found: %s)" % [name, scene_path])
			failed += 1
			continue

		var packed: PackedScene = load(scene_path)
		if packed == null:
			print("FAIL: %s (could not load scene)" % name)
			failed += 1
			continue

		var node := packed.instantiate()
		get_root().add_child(node)

		# Allow one frame to render
		await process_frame

		var img := get_root().get_viewport().get_texture().get_image()
		if img == null:
			print("FAIL: %s (no viewport image)" % name)
			get_root().remove_child(node)
			node.queue_free()
			failed += 1
			continue

		var out_path := SAVE_DIR + name + ".png"
		var err := img.save_png(out_path)
		if err == OK:
			print("PASS: screenshot saved — %s" % out_path)
			captured += 1
		else:
			print("FAIL: %s (save error %d)" % [name, err])
			failed += 1

		get_root().remove_child(node)
		node.queue_free()

	print("---")
	print("Screenshots complete: %d captured, %d failed" % [captured, failed])
	quit()
