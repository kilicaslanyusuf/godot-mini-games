extends Control

@onready var collector_button = $ButtonColumn/CollectorButton
@onready var dodge_button = $ButtonColumn/DodgeButton
@onready var target_button = $ButtonColumn/TargetButton
@onready var brick_button = $ButtonColumn/BrickButton
@onready var quit_button = $ButtonColumn/QuitButton

func _ready():
	collector_button.pressed.connect(_open_collector)
	dodge_button.pressed.connect(_open_dodge)
	target_button.pressed.connect(_open_target)
	brick_button.pressed.connect(_open_brick)
	quit_button.pressed.connect(_quit_game)

func _open_collector():
	get_tree().change_scene_to_file("res://collector_game.tscn")

func _open_dodge():
	get_tree().change_scene_to_file("res://dodge_trial.tscn")

func _open_target():
	get_tree().change_scene_to_file("res://target_blaster.tscn")

func _open_brick():
	get_tree().change_scene_to_file("res://brick_break_lite.tscn")

func _quit_game():
	get_tree().quit()
