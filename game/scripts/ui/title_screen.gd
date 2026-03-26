extends CanvasLayer

signal begin_pressed
signal continue_pressed

const FLAVOR_LINES: Array[String] = [
	"The road brought you here.",
	"Extract when it feels wrong.",
	"Silver only spends if you make it back.",
	"Three hundred years, and it is still waiting.",
]

const FLAVOR_CYCLE_TIME := 8.0

@onready var continue_btn: Button = $CenterContainer/VBoxContainer/Continue
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/Subtitle
@onready var flavor_label: Label = $CenterContainer/VBoxContainer/FlavorLine
@onready var begin_btn: Button = $CenterContainer/VBoxContainer/Begin

var _flavor_index: int = 0
var _flavor_timer: float = 0.0

func _ready() -> void:
	_flavor_index = randi() % FLAVOR_LINES.size()
	if flavor_label:
		flavor_label.text = FLAVOR_LINES[_flavor_index]

	begin_btn.pressed.connect(func():
		_play_click()
		begin_pressed.emit()
	)
	continue_btn.pressed.connect(func():
		_play_click()
		continue_pressed.emit()
	)

func _process(delta: float) -> void:
	_flavor_timer += delta
	if _flavor_timer >= FLAVOR_CYCLE_TIME:
		_flavor_timer = 0.0
		_flavor_index = (_flavor_index + 1) % FLAVOR_LINES.size()
		if flavor_label:
			flavor_label.text = FLAVOR_LINES[_flavor_index]

func set_continue_visible(show: bool) -> void:
	if continue_btn:
		continue_btn.visible = show

func _play_click() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
