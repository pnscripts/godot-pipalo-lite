extends CharacterBody2D
## A round runner that reads plain input actions; it does not know about touch at all.

const SPEED := 360.0
const JUMP := 640.0
const GRAVITY := 1700.0
const DASH := 900.0

var dash_left := 0.0
var facing := 1.0
var trail: Array[Vector2] = []


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if absf(dir.x) > 0.05:
		facing = signf(dir.x)
	if dash_left > 0.0:
		dash_left -= delta
		velocity.x = facing * DASH
		velocity.y = 0.0
	else:
		velocity.x = move_toward(velocity.x, dir.x * SPEED, 2600.0 * delta)
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -JUMP
	if Input.is_action_just_pressed("dash") and dash_left <= 0.0:
		dash_left = 0.16
	move_and_slide()
	position.x = clampf(position.x, 40.0, 1240.0)
	trail.push_front(position)
	if trail.size() > 10:
		trail.pop_back()
	queue_redraw()


func _draw() -> void:
	for i in trail.size():
		var p := trail[i] - position
		draw_circle(p, 26.0 - i * 2.0, Color(0.96, 0.66, 0.26, 0.06 * (10 - i) if dash_left > 0.0 else 0.0))
	draw_circle(Vector2.ZERO, 28.0, Color(0.96, 0.66, 0.26))
	draw_circle(Vector2(10 * facing, -6), 6.0, Color(0.1, 0.1, 0.12))
