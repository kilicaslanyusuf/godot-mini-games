extends Control

@onready var fullscreen_value_label = $SettingsBox/FullscreenRow/FullscreenValueLabel
@onready var fullscreen_toggle_button = $SettingsBox/FullscreenRow/FullscreenToggleButton

@onready var volume_value_label = $SettingsBox/VolumeRow/VolumeValueLabel
@onready var volume_down_button = $SettingsBox/VolumeRow/VolumeDownButton
@onready var volume_up_button = $SettingsBox/VolumeRow/VolumeUpButton

func _ready():
	fullscreen_toggle_button.pressed.connect(_on_fullscreen_toggle_pressed)
	volume_down_button.pressed.connect(_on_volume_down_pressed)
	volume_up_button.pressed.connect(_on_volume_up_pressed)
	update_ui()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mini_games_hub.tscn")

func update_ui():
	if AppState.fullscreen_enabled:
		fullscreen_value_label.text = "Açık"
	else:
		fullscreen_value_label.text = "Kapalı"

	volume_value_label.text = "%d%%" % AppState.master_volume

func _on_fullscreen_toggle_pressed():
	AppState.toggle_fullscreen()
	update_ui()

func _on_volume_down_pressed():
	AppState.change_master_volume(-10)
	update_ui()

func _on_volume_up_pressed():
	AppState.change_master_volume(10)
	update_ui()
