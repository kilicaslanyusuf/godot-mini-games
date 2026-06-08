extends Control

@onready var collector_label = $RecordsBox/CollectorLabel
@onready var dodge_label = $RecordsBox/DodgeLabel
@onready var target_label = $RecordsBox/TargetLabel
@onready var brick_label = $RecordsBox/BrickLabel
@onready var lane_label = $RecordsBox/LaneLabel

func _ready():
	load_records()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mini_games_hub.tscn")

func load_records():
	var collector_best = load_int_save("user://collector_rush_save.save", 0)
	var dodge_best = load_int_save("user://dodge_trial_save.save", 0)
	var target_best = load_int_save("user://target_blaster_save.save", 0)
	var lane_best = load_int_save("user://lane_dash_lite_save.save", 0)

	var brick_data = load_dict_save("user://brick_break_save.save")
	var brick_best_score = int(brick_data.get("best_score", 0))
	var brick_best_level = int(brick_data.get("best_level", 1))

	collector_label.text = "Collector Rush: En iyi skor %d" % collector_best
	dodge_label.text = "Dodge Trial: En iyi hayatta kalma %d sn" % dodge_best
	target_label.text = "Target Blaster: En iyi skor %d" % target_best
	brick_label.text = "Brick Break Lite: Rekor %d | En iyi seviye %d" % [brick_best_score, brick_best_level]
	lane_label.text = "Lane Dash Lite: En iyi skor %d" % lane_best

func load_int_save(path: String, default_value: int) -> int:
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			return int(file.get_var())
	return default_value

func load_dict_save(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Dictionary:
				return data
	return {}
