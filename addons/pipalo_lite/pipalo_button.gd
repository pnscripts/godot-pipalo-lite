@tool
@icon("res://addons/pipalo_lite/icons/button.svg")
class_name PipaloLiteButton
extends PipaloLiteTouchControl
## On-screen button for touch screens (Pipalo Lite by PN Scripts, MIT).
##
## Holds an input action while a finger is on it, so is_action_pressed(),
## is_action_just_pressed() and _unhandled_input() in your game code work unchanged.
## A finger that slides from one button onto another moves the press with it (slide on),
## which players expect for jump-and-shoot layouts. Toggle mode keeps the action held until
## the next tap.

signal pressed
signal released

## The input action this button holds.
@export var action: StringName = &"ui_accept"
## Text drawn in the middle (empty for none). Short words or one letter work best.
@export var text := "":
	set(v):
		text = v
		queue_redraw()
## Optional icon drawn in the middle instead of the text.
@export var icon: Texture2D:
	set(v):
		icon = v
		queue_redraw()
@export_enum("Circle", "Rounded rectangle") var shape := 0:
	set(v):
		shape = v
		queue_redraw()
## Tap once to hold the action, tap again to let go (crouch, run, aim).
@export var toggle_mode := false
## A finger sliding onto this button from elsewhere presses it.
@export var slide_on := true
## Font size of the text.
@export var font_size := 26

var is_down := false
var finger := -1


func _ready() -> void:
	super()
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(110, 110)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not _accepts(event):
		return
	if handle(event):
		get_viewport().set_input_as_handled()


func _hit(canvas_pos: Vector2) -> bool:
	var r := get_global_rect()
	if shape == 0:
		var rad := minf(r.size.x, r.size.y) * 0.5 + touch_margin
		return canvas_pos.distance_to(r.get_center()) <= rad
	return r.grow(touch_margin).has_point(canvas_pos)


## Feeds one touch event; returns true when the button used it.
func handle(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var pos := to_canvas(event.position)
		if event.pressed:
			if finger < 0 and _hit(pos):
				finger = event.index
				if toggle_mode:
					_set_down(not is_down)
				else:
					_set_down(true)
				return true
		elif event.index == finger:
			finger = -1
			if not toggle_mode:
				_set_down(false)
			return true
	elif event is InputEventScreenDrag:
		var pos := to_canvas(event.position)
		if event.index == finger:
			if not toggle_mode and not _hit(pos):
				# The finger slid away: let go, so another button can take it.
				finger = -1
				_set_down(false)
				return false
			return true
		if finger < 0 and slide_on and not toggle_mode and _hit(pos):
			finger = event.index
			_set_down(true)
			return true
	return false


func _set_down(down: bool) -> void:
	if down == is_down:
		return
	is_down = down
	if down:
		press_action(action)
		pressed.emit()
	else:
		release_action(action)
		released.emit()
	queue_redraw()


func release_all() -> void:
	finger = -1
	if is_down:
		_set_down(false)


func _draw() -> void:
	var a := pressed_opacity if is_down else idle_opacity
	var r := Rect2(Vector2.ZERO, size)
	var c := r.get_center()
	if shape == 0:
		var rad := minf(size.x, size.y) * 0.5
		draw_circle(c, rad * (0.95 if is_down else 1.0), Color(color, a * 0.6))
		draw_arc(c, rad - 1.5, 0, TAU, 48, Color(color, minf(a + 0.2, 1.0)), 3.0, true)
	else:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(color, a * 0.6)
		sb.border_color = Color(color, minf(a + 0.2, 1.0))
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(int(minf(size.x, size.y) * 0.25))
		sb.anti_aliasing = true
		draw_style_box(sb, r)
	var ink := Color(1, 1, 1, minf(0.55 + a, 1.0))
	if icon != null:
		var s := Vector2(minf(size.x, size.y), minf(size.x, size.y)) * 0.5
		draw_texture_rect(icon, Rect2(c - s * 0.5, s), false, ink)
	elif text != "":
		var f := get_theme_default_font()
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(f, c + Vector2(-w.x * 0.5, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
