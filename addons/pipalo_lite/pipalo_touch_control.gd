@tool
class_name PipaloLiteTouchControl
extends Control
## Base of the Pipalo on-screen controls: tracks its own fingers by touch index (so several
## controls work at the same time), hides itself when the player is not using touch, and
## releases everything it pressed when hidden, paused or freed.

## When the control is visible.
@export_enum("Touch players only", "Always", "Never (set visible yourself)") var show_when := 0
## Extra margin around the control that still catches a finger, in pixels.
@export var touch_margin := 16.0
## Look of the control.
@export var color := Color(1, 1, 1, 1):
	set(v):
		color = v
		queue_redraw()
@export_range(0.0, 1.0) var idle_opacity := 0.35
@export_range(0.0, 1.0) var pressed_opacity := 0.7

var _device: PipaloLiteDevice


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_device = _find_device()
	if _device != null:
		_device.device_changed.connect(func(_k, _f): _update_visibility())
	_update_visibility()


func _find_device() -> PipaloLiteDevice:
	var tree := get_tree()
	if tree != null and tree.root.has_node("PipaloLite"):
		return tree.root.get_node("PipaloLite") as PipaloLiteDevice
	return null


## Uses another PipaloLiteDevice (tests, split screen).
func set_device(device: PipaloLiteDevice) -> void:
	_device = device
	device.device_changed.connect(func(_k, _f): _update_visibility())
	_update_visibility()


func _update_visibility() -> void:
	match show_when:
		0:
			visible = _device != null and _device.is_touch()
		1:
			visible = true
	if not visible:
		release_all()


## Whether an event may reach the control. A hidden "touch players only" control still takes
## the first touch, which is the touch that makes it appear.
func _accepts(event: InputEvent) -> bool:
	# Controls get input before the Pipalo autoload (input runs from the last node up), and a
	# control that uses a touch stops it there, so tell the device about touches here.
	if _device != null and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		_device.observe(event)
	if is_visible_in_tree():
		return true
	if show_when == 0 and event is InputEventScreenTouch and event.pressed and get_parent() is CanvasItem and get_parent().is_visible_in_tree():
		visible = true
		return true
	return false


## Releases every finger and action the control holds.
func release_all() -> void:
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()


## Area that catches a touch, in the canvas coordinates of touch events.
func touch_rect() -> Rect2:
	return get_global_rect().grow(touch_margin)


## Touch positions arrive in viewport coordinates; this turns them into this control's canvas.
func to_canvas(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos if is_inside_tree() else screen_pos


static func press_action(action: StringName, strength := 1.0) -> void:
	if action == &"" or not InputMap.has_action(action):
		return
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	ev.strength = strength
	Input.parse_input_event(ev)
	Input.action_press(action, strength)


static func release_action(action: StringName) -> void:
	if action == &"" or not InputMap.has_action(action):
		return
	if Input.is_action_pressed(action):
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = false
		Input.parse_input_event(ev)
	Input.action_release(action)
