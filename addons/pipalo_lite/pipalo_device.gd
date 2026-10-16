class_name PipaloLiteDevice
extends Node
## Knows what the player is holding (Pipalo Lite by PN Scripts, MIT).
##
## Watches every input event and keeps the last kind of device used: "keyboard" (keys and
## mouse), "gamepad" or "touch", plus the gamepad family ("xbox", "playstation", "nintendo",
## "steam" or "generic") from the controller's name. Touch controls show themselves only for
## touch players.
##
## The editor plugin adds this node as the autoload "PipaloLite".

## Emitted when the kind of device or the gamepad family changes.
signal device_changed(kind: String, family: String)

const KEYBOARD := "keyboard"
const GAMEPAD := "gamepad"
const TOUCH := "touch"

## Stick or trigger movement smaller than this does not count as using the gamepad.
@export_range(0.0, 1.0) var axis_threshold := 0.5
## Mouse movement smaller than this (pixels in one event) does not switch back to keyboard.
@export var mouse_motion_threshold := 6.0
## Start in "touch" on phones and tablets (and on the web when a touch screen is present).
@export var detect_touch_at_start := true
## Mouse events never switch the device. On by default when Project Settings > Input Devices >
## Pointing > Emulate Touch From Mouse is on, so you can try touch controls with a mouse.
@export var ignore_mouse := false

var kind := KEYBOARD
var family := "generic"
## Device id of the last gamepad used (for Input.get_joy_name and vibration).
var gamepad_id := 0

var _touches := {}
var _last_touch_ms := -100000
## Mouse events this soon after a touch are treated as copies of the touch
## (Project Settings > Input Devices > Pointing > Emulate Touch From Mouse, and browsers).
const MOUSE_AFTER_TOUCH_MS := 500


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false):
		ignore_mouse = true
	if detect_touch_at_start:
		if OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available()):
			kind = TOUCH
	if Input.get_connected_joypads().size() > 0 and kind == KEYBOARD:
		family = family_of(Input.get_joy_name(Input.get_connected_joypads()[0]))
	Input.joy_connection_changed.connect(_on_joy_connection)


func is_touch() -> bool:
	return kind == TOUCH


func is_gamepad() -> bool:
	return kind == GAMEPAD


func _input(event: InputEvent) -> void:
	observe(event)


## Looks at one event and switches the device when it counts as real use. Returns true when
## the device changed. Called for every event by _input; tests and tools can call it directly.
func observe(event: InputEvent) -> bool:
	var new_kind := ""
	var new_family := family
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		new_kind = TOUCH
		_last_touch_ms = Time.get_ticks_msec()
		if event is InputEventScreenTouch:
			if event.pressed:
				_touches[event.index] = true
			else:
				_touches.erase(event.index)
	elif event is InputEventMouse and (ignore_mouse or not _touches.is_empty() or Time.get_ticks_msec() - _last_touch_ms < MOUSE_AFTER_TOUCH_MS):
		return false
	elif event is InputEventJoypadButton and event.pressed:
		new_kind = GAMEPAD
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= axis_threshold:
		new_kind = GAMEPAD
	elif event is InputEventKey and event.pressed:
		new_kind = KEYBOARD
	elif event is InputEventMouseButton and event.pressed:
		# Godot turns touches into mouse events for Controls; those must not switch away from touch.
		if event.device != InputEvent.DEVICE_ID_EMULATION:
			new_kind = KEYBOARD
	elif event is InputEventMouseMotion:
		if event.device != InputEvent.DEVICE_ID_EMULATION and event.relative.length() >= mouse_motion_threshold:
			new_kind = KEYBOARD
	if new_kind == "":
		return false
	if new_kind == GAMEPAD:
		gamepad_id = event.device
		new_family = family_of(Input.get_joy_name(event.device))
	return set_device(new_kind, new_family)


## Sets the device yourself (for example from a "controls" option). Returns true on change.
func set_device(new_kind: String, new_family := "") -> bool:
	if new_family == "":
		new_family = family
	if new_kind == kind and new_family == family:
		return false
	kind = new_kind
	family = new_family
	device_changed.emit(kind, family)
	return true


## Guesses the family from a controller name as SDL reports it.
static func family_of(joy_name: String) -> String:
	var n := joy_name.to_lower()
	if n.contains("xbox") or n.contains("xinput") or n.contains("x-box") or n.contains("microsoft"):
		return "xbox"
	if n.contains("playstation") or n.contains("dualshock") or n.contains("dualsense") or n.contains("ps3") or n.contains("ps4") or n.contains("ps5") or n.contains("sony"):
		return "playstation"
	if n.contains("nintendo") or n.contains("switch") or n.contains("joy-con") or n.contains("pro controller"):
		return "nintendo"
	if n.contains("steam"):
		return "steam"
	return "generic"


func _on_joy_connection(device: int, connected: bool) -> void:
	if connected and kind == GAMEPAD and device == gamepad_id:
		var f := family_of(Input.get_joy_name(device))
		set_device(GAMEPAD, f)
	elif not connected and kind == GAMEPAD and device == gamepad_id:
		set_device(TOUCH if OS.has_feature("mobile") else KEYBOARD)
