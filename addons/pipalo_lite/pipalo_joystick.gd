@tool
@icon("res://addons/pipalo_lite/icons/joystick.svg")
class_name PipaloLiteJoystick
extends PipaloLiteTouchControl
## On-screen joystick for touch screens (Pipalo Lite by PN Scripts, MIT).
##
## Presses four input actions with analog strength, so Input.get_vector() and
## Input.get_action_strength() in your existing code just work, and also gives the raw
## vector through output and the moved signal.
##
## Modes: Fixed stays where you put it; Floating appears where the finger lands inside the
## control's area; Following also slides along when the finger goes past the edge.

signal moved(vector: Vector2)
signal pressed
signal released

@export_enum("Fixed", "Floating", "Following") var mode := 1
## Radius of the base, in pixels. The knob moves up to this far.
@export var radius := 90.0:
	set(v):
		radius = v
		queue_redraw()
## Below this fraction of the radius the output is zero.
@export_range(0.0, 0.9) var deadzone := 0.15
## Shape of the response after the deadzone: 1 is linear, 2 gives finer control near the centre.
@export_range(0.5, 3.0) var response_curve := 1.0
## Snap the output to 8 directions (for menus and grid games).
@export var eight_directions := false
@export var action_left: StringName = &"ui_left"
@export var action_right: StringName = &"ui_right"
@export var action_up: StringName = &"ui_up"
@export var action_down: StringName = &"ui_down"
## Optional textures; when empty the joystick is drawn with circles.
@export var base_texture: Texture2D
@export var knob_texture: Texture2D

## Current output, length 0..1, after deadzone and curve.
var output := Vector2.ZERO
var finger := -1

var _rest_center := Vector2.ZERO
var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var _pressed := {}


func _ready() -> void:
	super()
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(radius, radius) * 2.4
	resized.connect(_reset_center)
	_reset_center.call_deferred()


func _reset_center() -> void:
	_rest_center = size * 0.5
	if finger < 0:
		_center = _rest_center
		_knob = _rest_center
	queue_redraw()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not _accepts(event):
		return
	if handle(event):
		get_viewport().set_input_as_handled()


## Feeds one touch event; returns true when the joystick used it.
func handle(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var pos := to_canvas(event.position)
		if event.pressed and finger < 0:
			var local := pos - get_global_rect().position
			var catch := touch_rect().has_point(pos) if mode != 0 else (local.distance_to(_rest_center) <= radius + touch_margin)
			if not catch:
				return false
			finger = event.index
			_center = local if mode != 0 else _rest_center
			_move_knob(local)
			pressed.emit()
			return true
		if not event.pressed and event.index == finger:
			_release()
			return true
	elif event is InputEventScreenDrag and event.index == finger:
		_move_knob(to_canvas(event.position) - get_global_rect().position)
		return true
	return false


func _move_knob(local: Vector2) -> void:
	var d := local - _center
	if mode == 2 and d.length() > radius:
		_center += d - d.limit_length(radius)
		d = local - _center
	d = d.limit_length(radius)
	_knob = _center + d
	_set_output(d / radius)
	queue_redraw()


func _set_output(raw: Vector2) -> void:
	var v := Vector2.ZERO
	var len := raw.length()
	if len > deadzone:
		var t := clampf((len - deadzone) / (1.0 - deadzone), 0.0, 1.0)
		t = pow(t, response_curve)
		v = raw.normalized() * t
		if eight_directions:
			var a := snappedf(v.angle(), PI / 4.0)
			v = Vector2.from_angle(a) * t
	output = v
	_apply_actions(v)
	moved.emit(v)


func _apply_actions(v: Vector2) -> void:
	var want := {
		action_left: maxf(-v.x, 0.0), action_right: maxf(v.x, 0.0),
		action_up: maxf(-v.y, 0.0), action_down: maxf(v.y, 0.0),
	}
	for action in want.keys():
		var s: float = want[action]
		if s > 0.0001:
			press_action(action, s)
			_pressed[action] = true
		elif _pressed.has(action):
			release_action(action)
			_pressed.erase(action)


func _release() -> void:
	finger = -1
	_center = _rest_center
	_knob = _rest_center
	output = Vector2.ZERO
	for action in _pressed.keys():
		release_action(action)
	_pressed.clear()
	moved.emit(Vector2.ZERO)
	released.emit()
	queue_redraw()


func release_all() -> void:
	if finger >= 0 or not _pressed.is_empty():
		_release()


func _draw() -> void:
	var active := finger >= 0
	var a := pressed_opacity if active else idle_opacity
	if mode != 0 and not active:
		a *= 0.7
	if base_texture != null:
		var s := Vector2(radius, radius) * 2.0
		draw_texture_rect(base_texture, Rect2(_center - s * 0.5, s), false, Color(1, 1, 1, a))
	else:
		draw_circle(_center, radius, Color(0, 0, 0, 0.25 * a / maxf(idle_opacity, 0.01)))
		draw_arc(_center, radius, 0, TAU, 64, Color(color, a), 3.0, true)
		draw_arc(_center, radius * deadzone, 0, TAU, 24, Color(color, a * 0.5), 1.5, true)
	if knob_texture != null:
		var k := Vector2(radius, radius) * 0.9
		draw_texture_rect(knob_texture, Rect2(_knob - k * 0.5, k), false, Color(1, 1, 1, minf(a + 0.2, 1.0)))
	else:
		draw_circle(_knob, radius * 0.42, Color(color, minf(a + 0.15, 1.0)))
