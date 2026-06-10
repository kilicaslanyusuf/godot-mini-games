extends Control

@onready var first_step_label = $AchievementsBox/FirstStepLabel
@onready var collector_label = $AchievementsBox/CollectorLabel
@onready var survivor_label = $AchievementsBox/SurvivorLabel
@onready var sharp_shooter_label = $AchievementsBox/SharpShooterLabel
@onready var brick_master_label = $AchievementsBox/BrickMasterLabel
@onready var lane_runner_label = $AchievementsBox/LaneRunnerLabel

func _ready():
	load_achievements()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mini_games_hub.tscn")

func load_achievements():
	var collector_best = load_int_save("user://collector_rush_save.save", 0)
	var dodge_best = load_int_save("user://dodge_trial_save.save", 0)
	var target_best = load_int_save("user://target_blaster_save.save", 0)
	var lane_best = load_int_save("user://lane_dash_lite_save.save", 0)

	var brick_data = load_dict_save("user://brick_break_save.save")
	var brick_best_score = int(brick_data.get("best_score", 0))
	var brick_best_level = int(brick_data.get("best_level", 1))

	var first_step_unlocked = (
		collector_best > 0
		or dodge_best > 0
		or target_best > 0
		or lane_best > 0
		or brick_best_score > 0
	)

	first_step_label.text = "İlk Adım: %s" % get_unlock_text(first_step_unlocked)
	collector_label.text = "Collector Rookie (10+): %s" % get_unlock_text(collector_best >= 10)
	survivor_label.text = "Survivor (15 sn): %s" % get_unlock_text(dodge_best >= 15)
	sharp_shooter_label.text = "Sharp Shooter (50+): %s" % get_unlock_text(target_best >= 50)
	brick_master_label.text = "Brick Master (Seviye 3): %s" % get_unlock_text(brick_best_level >= 3)
	lane_runner_label.text = "Lane Runner (20+): %s" % get_unlock_text(lane_best >= 20)

func get_unlock_text(unlocked: bool) -> String:
	if unlocked:
		return "Açıldı"
	return "Kilitli"

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
