extends CharacterBody2D

@export var speed := 500.0

var screen_size: Vector2
var clamp_margin_x := 80.0
var fixed_y := 0.0

func _ready():
	screen_size = get_viewport_rect().size
	fixed_y = global_position.y

func _physics_process(_delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity = Vector2(direction * speed, 0)
	move_and_slide()

	global_position.x = clamp(global_position.x, clamp_margin_x, screen_size.x - clamp_margin_x)
	global_position.y = fixed_y
