extends CharacterBody2D

@export var speed := 350.0

var screen_size: Vector2
var clamp_margin_x := 20.0
var fixed_y := 0.0

@onready var collision_shape = $CollisionShape2D

func _ready():
	screen_size = get_viewport_rect().size
	fixed_y = global_position.y

	var shape = collision_shape.shape
	if shape is CircleShape2D:
		clamp_margin_x = max(80.0, shape.radius)

func _physics_process(_delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity = Vector2(direction * speed, 0)
	move_and_slide()

	global_position.x = clamp(global_position.x, clamp_margin_x, screen_size.x - clamp_margin_x)
	global_position.y = fixed_y
