extends CanvasLayer

signal prologue_finished

@onready var begin_button: Button = $Background/VBoxContainer/BeginButton

func _ready() -> void:
	begin_button.pressed.connect(_on_begin_pressed)

func _on_begin_pressed() -> void:
	prologue_finished.emit()
