extends CanvasLayer
class_name VictoryScreen

signal new_journey_requested
signal return_to_menu_requested
signal view_credits_requested

@onready var rings_label: Label = $PanelContainer/VBoxContainer/StatsBox/RingsLabel
@onready var loot_label: Label = $PanelContainer/VBoxContainer/StatsBox/LootLabel
@onready var xp_label: Label = $PanelContainer/VBoxContainer/StatsBox/XPLabel
@onready var seed_label: Label = $PanelContainer/VBoxContainer/StatsBox/SeedLabel

func _ready() -> void:
	$PanelContainer/VBoxContainer/NewJourneyButton.pressed.connect(func(): new_journey_requested.emit())
	$PanelContainer/VBoxContainer/ReturnToMenuButton.pressed.connect(func(): return_to_menu_requested.emit())
	$PanelContainer/VBoxContainer/ViewCreditsButton.pressed.connect(func(): view_credits_requested.emit())

func populate(rings_cleared: int, loot_banked: int, xp_banked: int, seed: int) -> void:
	rings_label.text = "Rings Cleared: %d" % rings_cleared
	loot_label.text = "Total Loot Banked: %d" % loot_banked
	xp_label.text = "Total XP Banked: %d" % xp_banked
	seed_label.text = "Run Seed: %d" % seed
