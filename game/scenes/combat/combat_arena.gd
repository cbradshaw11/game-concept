extends Node2D
class_name CombatArena

const EnemyController = preload("res://scripts/core/enemy_controller.gd")
const PlayerController = preload("res://scripts/core/player_controller.gd")

signal attack_hook_triggered
signal dodge_hook_triggered
signal guard_hook_changed(is_guarding: bool)
signal encounter_cleared(enemy_count: int)

@onready var player: PlayerController = $Player
@onready var player_sprite: Sprite2D = $Player/PlayerSprite
@onready var combat_status: Label = $HUD/CombatStatus
@onready var hp_bar: ProgressBar = $HUD/StatsPanel/StatsVBox/HPBar
@onready var stamina_bar: ProgressBar = $HUD/StatsPanel/StatsVBox/StaminaBar
@onready var poise_bar: ProgressBar = $HUD/StatsPanel/StatsVBox/PoiseBar
@onready var enemy_container: Node2D = $EnemyContainer
@onready var camera: Camera2D = $Camera
@onready var arena_bg: Sprite2D = $ArenaBG

var ring_id: String = "inner"
var seed: int = 0
var attack_count: int = 0
var dodge_count: int = 0
var guard_active: bool = false
var enemies: Array[EnemyController] = []
var enemy_sprites: Array[Sprite2D] = []
var enemy_nodes: Array[Node2D] = []
var encounter_enemy_count: int = 0
var encounter_completed: bool = false

# Camera shake state
var _shake_amount: float = 0.0
var _shake_timer: float = 0.0
var _camera_origin: Vector2 = Vector2.ZERO

# Hit flash timers per enemy
var _hit_flash_timers: Array[float] = []

const SPRITE_BASE := "res://assets/sprites/"
const ENEMY_SPRITE_NAMES := {
	"grunt": "enemy_grunt.png",
	"defender": "enemy_defender.png",
	"ranged": "enemy_ranged.png",
	"warden": "enemy_warden.png",
}

func _ready() -> void:
	player.attack_triggered.connect(_on_attack_triggered)
	player.dodge_triggered.connect(_on_dodge_triggered)
	player.guard_changed.connect(_on_guard_changed)
	_camera_origin = camera.offset
	_load_background()
	_load_player_sprite()
	_update_hud()
	# Start combat music when arena becomes active
	if AudioManager:
		AudioManager.play_combat_music()

func _load_background() -> void:
	# Check for ring-specific background first, fallback to default
	var bg_name := "arena_bg.png"
	if ring_id == "mid":
		bg_name = "arena_bg_mid.png"
	var bg_path := "res://assets/backgrounds/" + bg_name
	if ResourceLoader.exists(bg_path):
		arena_bg.texture = load(bg_path) as Texture2D
	elif ResourceLoader.exists("res://assets/backgrounds/arena_bg.png"):
		arena_bg.texture = load("res://assets/backgrounds/arena_bg.png") as Texture2D

func _load_player_sprite() -> void:
	var path := SPRITE_BASE + "player.png"
	if ResourceLoader.exists(path):
		player_sprite.texture = load(path) as Texture2D

func set_context(next_ring_id: String, next_seed: int, enemy_count: int = 1) -> void:
	ring_id = next_ring_id
	seed = next_seed
	attack_count = 0
	dodge_count = 0
	guard_active = false
	encounter_enemy_count = max(1, enemy_count)
	encounter_completed = false
	_load_background()
	_spawn_enemies(encounter_enemy_count)
	player.set_guarding(false)
	_update_hud()

func set_arena_active(is_active: bool) -> void:
	visible = is_active
	process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	_update_camera_shake(delta)
	_update_hit_flashes(delta)

	if enemies.is_empty() or encounter_completed:
		return
	var player_zone := _player_zone()
	for index in enemies.size():
		var enemy := enemies[index]
		if enemy.state == EnemyController.EnemyState.DEAD:
			continue
		var distance_to_player := absf(float(index - player_zone)) + 0.5
		enemy.tick(distance_to_player, delta)
	if _all_enemies_defeated():
		encounter_completed = true
		if AudioManager:
			AudioManager.play_victory()
		encounter_cleared.emit(encounter_enemy_count)
	_update_hud()

func _on_attack_triggered() -> void:
	attack_count += 1
	_apply_damage_to_front_enemy(40)
	attack_hook_triggered.emit()
	if AudioManager:
		AudioManager.play_attack()
	_update_hud()

func _on_dodge_triggered() -> void:
	dodge_count += 1
	dodge_hook_triggered.emit()
	if AudioManager:
		AudioManager.play_dodge()
	_update_hud()

func _on_guard_changed(is_guarding: bool) -> void:
	guard_active = is_guarding
	guard_hook_changed.emit(is_guarding)
	if is_guarding and AudioManager:
		AudioManager.play_guard()
	_update_hud()

func _update_hud() -> void:
	# Debug status label (small, subtle)
	var state_parts: PackedStringArray = []
	for index in enemies.size():
		var enemy := enemies[index]
		state_parts.append("E%d:%s(%d)" % [index + 1, EnemyController.state_name(enemy.state), enemy.health])
	var enemies_text := " | ".join(state_parts)
	combat_status.text = "Ring %s | Atk %d Dodge %d Guard %s | %s" % [
		ring_id,
		attack_count,
		dodge_count,
		"On" if guard_active else "Off",
		enemies_text,
	]

	# Stat bars
	if stamina_bar:
		stamina_bar.value = (player.stamina / float(player.max_stamina)) * 100.0


func _spawn_enemies(count: int) -> void:
	enemies.clear()
	_hit_flash_timers.clear()

	for node in enemy_nodes:
		if is_instance_valid(node):
			node.queue_free()
	enemy_nodes.clear()
	enemy_sprites.clear()

	var archetypes := ["grunt", "ranged", "defender"]
	var arena_width := 960.0
	var spacing := arena_width / float(count + 1)

	for i in count:
		enemies.append(EnemyController.new(100, 3.5, 1.2))
		_hit_flash_timers.append(0.0)

		var archetype := "grunt"
		if count == 1 and ring_id == "outer":
			archetype = "warden"
		elif i < archetypes.size():
			archetype = archetypes[i]
		else:
			archetype = archetypes[i % archetypes.size()]

		var node := Node2D.new()
		var sprite := Sprite2D.new()

		var sprite_name := ENEMY_SPRITE_NAMES.get(archetype, "enemy_grunt.png") as String
		var tex_path := SPRITE_BASE + sprite_name
		if ResourceLoader.exists(tex_path):
			sprite.texture = load(tex_path) as Texture2D

		if archetype == "warden":
			sprite.scale = Vector2(2.0, 2.0)

		node.add_child(sprite)
		enemy_container.add_child(node)
		node.position = Vector2(spacing * (i + 1), 280.0)

		enemy_nodes.append(node)
		enemy_sprites.append(sprite)


func _player_zone() -> int:
	var zone := int(round(player.position.x / 160.0))
	return clampi(zone, 0, max(0, enemies.size() - 1))


func _apply_damage_to_front_enemy(damage: int) -> void:
	for i in enemies.size():
		var enemy := enemies[i]
		if enemy.state != EnemyController.EnemyState.DEAD:
			var prev_state := enemy.state
			enemy.apply_damage(damage, true)

			# Hit flash
			if i < _hit_flash_timers.size():
				_hit_flash_timers[i] = 0.1

			if enemy.state == EnemyController.EnemyState.DEAD and prev_state != EnemyController.EnemyState.DEAD:
				# Death: dissolve + heavy shake
				_start_death_dissolve(i)
				trigger_screen_shake(5.0, 0.3)
				if AudioManager:
					AudioManager.play_death()
			else:
				# Regular hit: light shake
				trigger_screen_shake(2.0, 0.12)
				if AudioManager:
					AudioManager.play_hit()
			return


func _all_enemies_defeated() -> bool:
	for enemy in enemies:
		if enemy.state != EnemyController.EnemyState.DEAD:
			return false
	return true


# ─── Hit Flash ────────────────────────────────────────────────────────────────

func _update_hit_flashes(delta: float) -> void:
	for i in _hit_flash_timers.size():
		if _hit_flash_timers[i] > 0.0:
			_hit_flash_timers[i] -= delta
			if i < enemy_sprites.size() and is_instance_valid(enemy_sprites[i]):
				if _hit_flash_timers[i] > 0.0:
					enemy_sprites[i].modulate = Color(2.0, 2.0, 2.0, 1.0)
				else:
					enemy_sprites[i].modulate = Color(1.0, 1.0, 1.0, 1.0)


# ─── Death Dissolve ───────────────────────────────────────────────────────────

func _start_death_dissolve(enemy_index: int) -> void:
	if enemy_index >= enemy_sprites.size():
		return
	var sprite := enemy_sprites[enemy_index]
	if not is_instance_valid(sprite):
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 0.0), 0.4)


# ─── Screen Shake ─────────────────────────────────────────────────────────────

func trigger_screen_shake(amount: float = 6.0, duration: float = 0.25) -> void:
	_shake_amount = amount
	_shake_timer = duration

func _update_camera_shake(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var shake_x := randf_range(-_shake_amount, _shake_amount)
		var shake_y := randf_range(-_shake_amount, _shake_amount)
		camera.offset = _camera_origin + Vector2(shake_x, shake_y)
	else:
		camera.offset = _camera_origin
