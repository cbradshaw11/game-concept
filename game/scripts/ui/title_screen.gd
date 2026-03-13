extends CanvasLayer
class_name TitleScreen

signal new_game_requested
signal continue_requested

@onready var new_game_button: Button = $CenterContainer/VBoxContainer/NewGame
@onready var continue_button: Button = $CenterContainer/VBoxContainer/Continue
@onready var new_game_confirm: ConfirmationDialog = $NewGameConfirm

func _ready() -> void:
	var save_exists := FileAccess.file_exists("user://savegame.json")
	continue_button.disabled = not save_exists
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	$CenterContainer/VBoxContainer/Quit.pressed.connect(_on_quit_pressed)
	new_game_confirm.confirmed.connect(_on_new_game_confirmed)

func _on_new_game_pressed() -> void:
	var save_exists := FileAccess.file_exists("user://savegame.json")
	if save_exists:
		new_game_confirm.popup_centered()
	else:
		new_game_requested.emit()

func _on_new_game_confirmed() -> void:
	new_game_requested.emit()

func _on_continue_pressed() -> void:
	continue_requested.emit()

func _on_quit_pressed() -> void:
	get_tree().quit()
