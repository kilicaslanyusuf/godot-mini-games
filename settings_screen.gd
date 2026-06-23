extends Control

@onready var volume_value_label = $SettingsBox/VolumeRow/VolumeValueLabel
@onready var volume_down_button = $SettingsBox/VolumeRow/VolumeDownButton
@onready var volume_up_button = $SettingsBox/VolumeRow/VolumeUpButton

@onready var reset_button = $SettingsBox/ResetRow/ResetButton
@onready var reset_status_label = $ResetStatusLabel

var confirm_reset_pending := false

var progress_save_files = [
	"user://collector_rush_save.save",
	"user://dodge_trial_save.save",
	"user://target_blaster_save.save",
	"user://brick_break_save.save",
	"user://lane_dash_lite_save.save"
]

func _ready():
	volume_down_button.pressed.connect(_on_volume_down_pressed)
	volume_up_button.pressed.connect(_on_volume_up_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	update_ui()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mini_games_hub.tscn")

func update_ui():
	volume_value_label.text = "%d%%" % AppState.master_volume

	if confirm_reset_pending:
		reset_button.text = "Onayla"
	else:
		reset_button.text = "Sıfırla"

func clear_reset_confirmation():
	if confirm_reset_pending:
		confirm_reset_pending = false
		reset_status_label.text = ""
		update_ui()

func _on_volume_down_pressed():
	clear_reset_confirmation()
	AppState.change_master_volume(-10)
	update_ui()

func _on_volume_up_pressed():
	clear_reset_confirmation()
	AppState.change_master_volume(10)
	update_ui()

func _on_reset_button_pressed():
	if not confirm_reset_pending:
		confirm_reset_pending = true
		reset_status_label.text = "Tekrar basarsan tüm ilerleme silinecek!"
		update_ui()
		return

	reset_all_progress()
	confirm_reset_pending = false
	update_ui()
	reset_status_label.text = "İlerleme sıfırlandı."

func reset_all_progress():
	for path in progress_save_files:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
