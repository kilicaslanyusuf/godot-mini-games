extends Control

@onready var collector_button = $ButtonColumn/CollectorButton
@onready var dodge_button = $ButtonColumn/DodgeButton
@onready var target_button = $ButtonColumn/TargetButton
@onready var brick_button = $ButtonColumn/BrickButton
@onready var lane_button = $ButtonColumn/LaneButton
@onready var quit_button = $ButtonColumn/QuitButton

@onready var info_label = $InfoLabel
@onready var records_label = $RecordsLabel
@onready var controls_label = $ControlsLabel

func _ready():
	collector_button.pressed.connect(_open_collector)
	dodge_button.pressed.connect(_open_dodge)
	target_button.pressed.connect(_open_target)
	brick_button.pressed.connect(_open_brick)
	lane_button.pressed.connect(_open_lane)
	quit_button.pressed.connect(_quit_game)

	collector_button.mouse_entered.connect(func(): show_game_info("collector"))
	dodge_button.mouse_entered.connect(func(): show_game_info("dodge"))
	target_button.mouse_entered.connect(func(): show_game_info("target"))
	brick_button.mouse_entered.connect(func(): show_game_info("brick"))
	lane_button.mouse_entered.connect(func(): show_game_info("lane"))
	quit_button.mouse_entered.connect(func(): show_game_info("quit"))

	collector_button.focus_entered.connect(func(): show_game_info("collector"))
	dodge_button.focus_entered.connect(func(): show_game_info("dodge"))
	target_button.focus_entered.connect(func(): show_game_info("target"))
	brick_button.focus_entered.connect(func(): show_game_info("brick"))
	lane_button.focus_entered.connect(func(): show_game_info("lane"))
	quit_button.focus_entered.connect(func(): show_game_info("quit"))

	apply_last_game_focus()

func apply_last_game_focus():
	match AppState.last_game:
		"collector":
			collector_button.grab_focus()
		"dodge":
			dodge_button.grab_focus()
		"target":
			target_button.grab_focus()
		"brick":
			brick_button.grab_focus()
		"lane":
			lane_button.grab_focus()
		_:
			collector_button.grab_focus()

	show_game_info(AppState.last_game)

func show_game_info(game_name: String):
	match game_name:
		"collector":
			var best_score = load_int_save("user://collector_rush_save.save", 0)
			info_label.text = "Collector Rush: topla, hazarddan kaç, bonus zamanı kap."
			records_label.text = "Rekor skor: %d" % best_score
			controls_label.text = "Kontrol: Ok tuşları | Enter başlat | ESC hub"

		"dodge":
			var best_time = load_int_save("user://dodge_trial_save.save", 0)
			info_label.text = "Dodge Trial: düşmanlardan kaç, süre dolana kadar hayatta kal."
			records_label.text = "En iyi hayatta kalma: %d sn" % best_time
			controls_label.text = "Kontrol: Ok tuşları | Enter başlat | ESC hub"

		"target":
			var best_score = load_int_save("user://target_blaster_save.save", 0)
			info_label.text = "Target Blaster: hedefi vur, combo yap, kaçırma."
			records_label.text = "Rekor skor: %d" % best_score
			controls_label.text = "Kontrol: Sağ/sol hareket | Space ateş | ESC hub"

		"brick":
			var data = load_dict_save("user://brick_break_save.save")
			var best_score = int(data.get("best_score", 0))
			var best_level = int(data.get("best_level", 1))
			info_label.text = "Brick Break Lite: tuğlaları kır, canı koru, level atla."
			records_label.text = "Rekor: %d | En iyi seviye: %d" % [best_score, best_level]
			controls_label.text = "Kontrol: Sağ/sol | Space başlat | ESC hub"

		"lane":
			var best_score = load_int_save("user://lane_dash_lite_save.save", 0)
			info_label.text = "Lane Dash Lite: 3 şeritte kaç, engelleri atlat, hızla baş et."
			records_label.text = "Rekor skor: %d" % best_score
			controls_label.text = "Kontrol: Sağ/sol şerit | Enter başlat | ESC hub"

		"quit":
			info_label.text = "Oyundan çık."
			records_label.text = "Paket kapanır."
			controls_label.text = "Kontrol: Tıkla ve çık"

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

func _open_collector():
	AppState.last_game = "collector"
	get_tree().change_scene_to_file("res://collector_game.tscn")

func _open_dodge():
	AppState.last_game = "dodge"
	get_tree().change_scene_to_file("res://dodge_trial.tscn")

func _open_target():
	AppState.last_game = "target"
	get_tree().change_scene_to_file("res://target_blaster.tscn")

func _open_brick():
	AppState.last_game = "brick"
	get_tree().change_scene_to_file("res://brick_break_lite.tscn")

func _open_lane():
	AppState.last_game = "lane"
	get_tree().change_scene_to_file("res://lane_dash_lite.tscn")

func _quit_game():
	get_tree().quit()
