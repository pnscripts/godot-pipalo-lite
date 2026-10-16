extends SceneTree
## Pipalo test runner.
##
##   godot --headless --path project -s tests/run_tests.gd
##
## Touch, key, mouse and gamepad events are built in code and fed to the nodes, so the tests
## need no device and no display. Exit code 0 when all pass.

var _failures: Array[String] = []
var _checks := 0
var _passed := 0
var _failed := 0
var _added: Array[Node] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in ["t_left", "t_right", "t_up", "t_down", "t_jump", "t_fire", "t_menu"]:
		if InputMap.has_action(a):
			InputMap.erase_action(a)
		InputMap.add_action(a, 0.0)
	InputMap.action_add_event("t_jump", key(KEY_SPACE))
	InputMap.action_add_event("t_jump", pad(JOY_BUTTON_A))
	InputMap.action_add_event("t_fire", mouse_button(MOUSE_BUTTON_LEFT))
	InputMap.action_add_event("t_fire", key(KEY_F))
	InputMap.action_add_event("t_fire", pad(JOY_BUTTON_RIGHT_SHOULDER))
	InputMap.action_add_event("t_menu", pad(JOY_BUTTON_START))
	var m := InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_LEFT_X
	m.axis_value = -1.0
	InputMap.action_add_event("t_left", m)
	var tests := []
	for meth in get_script().get_script_method_list():
		if String(meth["name"]).begins_with("test_"):
			tests.append(String(meth["name"]))
	for t in tests:
		var before := _failures.size()
		await call(t)
		_cleanup()
		if _failures.size() == before:
			_passed += 1
			print("ok   ", t)
		else:
			_failed += 1
			print("FAIL ", t)
			for f in _failures.slice(before):
				print("     ", f)
	print("")
	print("%d tests, %d passed, %d failed, %d checks" % [_passed + _failed, _passed, _failed, _checks])
	quit(0 if _failed == 0 else 1)


func _cleanup() -> void:
	for n in _added:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.free()
	_added.clear()
	for a in ["t_left", "t_right", "t_up", "t_down", "t_jump", "t_fire"]:
		Input.action_release(a)


func check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func eq(a, b, msg: String) -> void:
	check(typeof(a) == typeof(b) and a == b, "%s: got %s, want %s" % [msg, a, b])


func near(a: float, b: float, tol: float, msg: String) -> void:
	check(absf(a - b) <= tol, "%s: %s vs %s" % [msg, a, b])


func add(n: Node) -> Node:
	root.add_child(n)
	_added.append(n)
	return n


func key(code: Key, pressed := true) -> InputEventKey:
	var k := InputEventKey.new()
	k.physical_keycode = code
	k.pressed = pressed
	return k


func pad(b: JoyButton, pressed := true, device := 0) -> InputEventJoypadButton:
	var j := InputEventJoypadButton.new()
	j.button_index = b
	j.pressed = pressed
	j.device = device
	return j


func axis(ax: JoyAxis, v: float) -> InputEventJoypadMotion:
	var m := InputEventJoypadMotion.new()
	m.axis = ax
	m.axis_value = v
	return m


func mouse_button(b: MouseButton, pressed := true) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = b
	e.pressed = pressed
	return e


func touch(index: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var t := InputEventScreenTouch.new()
	t.index = index
	t.position = pos
	t.pressed = pressed
	return t


func drag(index: int, pos: Vector2, rel := Vector2.ZERO) -> InputEventScreenDrag:
	var d := InputEventScreenDrag.new()
	d.index = index
	d.position = pos
	d.relative = rel
	return d


func device(kind := "touch") -> PipaloLiteDevice:
	var d := PipaloLiteDevice.new()
	d.detect_touch_at_start = false
	add(d)
	d.ignore_mouse = false
	d.set_device(kind, "generic")
	return d


func joystick(mode: int, dev: PipaloLiteDevice) -> PipaloLiteJoystick:
	var j := PipaloLiteJoystick.new()
	j.mode = mode
	j.radius = 100.0
	j.deadzone = 0.2
	j.action_left = &"t_left"
	j.action_right = &"t_right"
	j.action_up = &"t_up"
	j.action_down = &"t_down"
	add(j)
	j.position = Vector2(0, 300)
	j.size = Vector2(300, 300)
	j.set_device(dev)
	j._reset_center()
	return j


func button(pos: Vector2, action: StringName, dev: PipaloLiteDevice) -> PipaloLiteButton:
	var b := PipaloLiteButton.new()
	b.action = action
	b.touch_margin = 0.0
	add(b)
	b.position = pos
	b.size = Vector2(100, 100)
	b.set_device(dev)
	return b


# ------------------------------------------------------------------ device

func test_device_follows_events() -> void:
	var d := device("keyboard")
	var log := []
	d.device_changed.connect(func(k, f): log.append(k))
	check(d.observe(touch(0, Vector2(5, 5), true)), "touch switches")
	eq(d.kind, "touch", "touch")
	check(not d.observe(drag(0, Vector2(9, 9))), "same device: no change")
	d.observe(touch(0, Vector2(9, 9), false))
	d._last_touch_ms = -100000
	check(not d.observe(axis(JOY_AXIS_LEFT_X, 0.3)), "small stick movement ignored")
	check(d.observe(axis(JOY_AXIS_LEFT_X, 0.8)), "stick switches")
	eq(d.kind, "gamepad", "gamepad")
	check(not d.observe(key(KEY_A, false)), "key release ignored")
	check(d.observe(key(KEY_A)), "key press switches")
	d.observe(pad(JOY_BUTTON_A))
	var mm := InputEventMouseMotion.new()
	mm.relative = Vector2(2, 1)
	check(not d.observe(mm), "tiny mouse motion ignored")
	mm.relative = Vector2(20, 0)
	check(d.observe(mm), "mouse motion switches")
	eq(log, ["touch", "gamepad", "keyboard", "gamepad", "keyboard"], "signals")


func test_device_ignores_mouse_copies_of_touches() -> void:
	var d := device("keyboard")
	d.observe(touch(0, Vector2(5, 5), true))
	var copy := mouse_button(MOUSE_BUTTON_LEFT)
	copy.device = InputEvent.DEVICE_ID_EMULATION
	check(not d.observe(copy), "emulated mouse ignored")
	var real := mouse_button(MOUSE_BUTTON_LEFT)
	check(not d.observe(real), "mouse while a finger is down ignored")
	d.observe(touch(0, Vector2(5, 5), false))
	check(not d.observe(real), "mouse right after a touch ignored")
	d._last_touch_ms = -100000
	check(d.observe(real), "later mouse switches")
	d.set_device("touch")
	d._last_touch_ms = -100000
	d.ignore_mouse = true
	check(not d.observe(real), "ignore_mouse")
	eq(d.kind, "touch", "still touch")


func test_family_from_names() -> void:
	eq(PipaloLiteDevice.family_of("Xbox Series Controller"), "xbox", "xbox")
	eq(PipaloLiteDevice.family_of("XInput Gamepad (GLFW)"), "xbox", "xinput")
	eq(PipaloLiteDevice.family_of("PS5 Controller"), "playstation", "ps5")
	eq(PipaloLiteDevice.family_of("Sony DualSense Wireless Controller"), "playstation", "dualsense")
	eq(PipaloLiteDevice.family_of("Nintendo Switch Pro Controller"), "nintendo", "switch")
	eq(PipaloLiteDevice.family_of("Steam Virtual Gamepad"), "steam", "steam")
	eq(PipaloLiteDevice.family_of("8BitDo SN30"), "generic", "other")


# ------------------------------------------------------------------ joystick

func test_joystick_floating_strength_and_release() -> void:
	var d := device()
	var j := joystick(1, d)
	check(j.visible, "visible for touch")
	check(j.handle(touch(0, Vector2(50, 350), true)), "floating catches anywhere in the area")
	eq(j.output, Vector2.ZERO, "no output at the start point")
	j.handle(drag(0, Vector2(110, 350)))
	near(j.output.x, (0.6 - 0.2) / 0.8, 0.001, "deadzone remapped")
	near(Input.get_action_strength("t_right"), j.output.x, 0.001, "right action strength")
	check(not Input.is_action_pressed("t_left"), "left not pressed")
	j.handle(drag(0, Vector2(50, 600)))
	near(j.output.y, 1.0, 0.001, "clamped to the radius")
	check(not Input.is_action_pressed("t_right"), "right released when not pushed")
	check(Input.is_action_pressed("t_down"), "down pressed")
	check(j.handle(touch(0, Vector2(50, 600), false)), "lift")
	eq(j.output, Vector2.ZERO, "output zero after lift")
	check(not Input.is_action_pressed("t_down"), "actions released after lift")
	j.handle(touch(1, Vector2(150, 450), true))
	j.handle(drag(1, Vector2(160, 450)))
	eq(j.output, Vector2.ZERO, "inside the deadzone")


func test_joystick_fixed_and_following() -> void:
	var d := device()
	var f := joystick(0, d)
	check(not f.handle(touch(0, Vector2(5, 305), true)), "fixed ignores a touch outside the base")
	check(f.handle(touch(0, Vector2(150, 450), true)), "fixed takes a touch on the base")
	f.handle(drag(0, Vector2(150, 250)))
	near(f.output.y, -1.0, 0.001, "fixed up")
	f.handle(touch(0, Vector2(150, 250), false))
	var g := joystick(2, d)
	g.handle(touch(3, Vector2(100, 400), true))
	g.handle(drag(3, Vector2(400, 400)))
	near(g._center.x, 300.0, 0.01, "following base slides after the finger")
	near(g.output.x, 1.0, 0.001, "full output while following")


func test_joystick_eight_directions_and_curve() -> void:
	var d := device()
	var j := joystick(1, d)
	j.eight_directions = true
	j.handle(touch(0, Vector2(100, 400), true))
	j.handle(drag(0, Vector2(190, 430)))
	near(j.output.angle(), 0.0, 0.001, "snapped to right")
	j.handle(drag(0, Vector2(170, 470)))
	near(j.output.angle(), PI / 4.0, 0.001, "snapped to down-right")
	j.eight_directions = false
	j.response_curve = 2.0
	j.handle(drag(0, Vector2(160, 400)))
	near(j.output.x, pow(0.5, 2.0), 0.001, "squared response")


func test_joystick_hides_and_releases_for_other_devices() -> void:
	var d := device()
	var j := joystick(1, d)
	j.handle(touch(0, Vector2(100, 400), true))
	j.handle(drag(0, Vector2(190, 400)))
	check(Input.is_action_pressed("t_right"), "pressed")
	d.observe(key(KEY_A))
	check(not j.visible, "hidden for keyboard players")
	check(not Input.is_action_pressed("t_right"), "released when hidden")
	eq(j.finger, -1, "finger forgotten")
	j.show_when = 1
	j._update_visibility()
	check(j.visible, "always visible mode")


func test_hidden_control_takes_the_first_touch() -> void:
	var d := device("keyboard")
	var b := button(Vector2(500, 500), &"t_jump", d)
	check(not b.visible, "hidden for keyboard")
	b._input(touch(0, Vector2(550, 550), true))
	check(b.visible and b.is_down, "first touch shows it and presses it")
	eq(d.kind, "touch", "device switched by the control")


# ------------------------------------------------------------------ buttons

func test_button_press_release_and_multitouch() -> void:
	var d := device()
	var jump := button(Vector2(500, 500), &"t_jump", d)
	var fire := button(Vector2(650, 500), &"t_fire", d)
	var log := []
	jump.pressed.connect(func(): log.append("down"))
	jump.released.connect(func(): log.append("up"))
	check(jump.handle(touch(0, Vector2(550, 550), true)), "hit")
	check(Input.is_action_pressed("t_jump"), "action held")
	check(fire.handle(touch(1, Vector2(700, 550), true)), "second finger on another button")
	check(Input.is_action_pressed("t_fire"), "both held")
	check(not jump.handle(touch(1, Vector2(700, 550), false)), "other finger's lift ignored")
	check(Input.is_action_pressed("t_jump"), "still held")
	jump.handle(touch(0, Vector2(550, 550), false))
	check(not Input.is_action_pressed("t_jump"), "released")
	eq(log, ["down", "up"], "signals")
	check(not jump.handle(touch(2, Vector2(505, 505), true)), "corner outside the circle")


func test_button_slide_off_and_on() -> void:
	var d := device()
	var a := button(Vector2(500, 500), &"t_jump", d)
	var b := button(Vector2(610, 500), &"t_fire", d)
	a.handle(touch(0, Vector2(550, 550), true))
	var ev := drag(0, Vector2(660, 550))
	check(not a.handle(ev), "a lets the finger go")
	check(b.handle(ev), "b takes it")
	check(not Input.is_action_pressed("t_jump") and Input.is_action_pressed("t_fire"), "press moved with the finger")
	b.slide_on = false
	b.handle(touch(0, Vector2(660, 550), false))
	a.handle(touch(0, Vector2(550, 550), true))
	var ev2 := drag(0, Vector2(660, 550))
	a.handle(ev2)
	check(not b.handle(ev2), "slide_on off")


func test_button_toggle() -> void:
	var d := device()
	var b := button(Vector2(500, 500), &"t_fire", d)
	b.toggle_mode = true
	b.handle(touch(0, Vector2(550, 550), true))
	b.handle(touch(0, Vector2(550, 550), false))
	check(Input.is_action_pressed("t_fire"), "held after the first tap")
	b.handle(touch(0, Vector2(550, 550), true))
	b.handle(touch(0, Vector2(550, 550), false))
	check(not Input.is_action_pressed("t_fire"), "released after the second tap")
	b.shape = 1
	check(b._hit(Vector2(503, 503)), "rectangle shape hits the corner")


# ------------------------------------------------------------------ gestures

func test_safe_area_and_plugin_files() -> void:
	var s := PipaloLiteSafeArea.new()
	s.minimum_margin = 30
	add(s)
	eq(s.get_theme_constant("margin_left"), 30, "minimum margin headless")
	eq(s.safe_insets(), Rect2(), "no insets headless")
	for f in ["plugin.cfg", "plugin.gd", "pipalo_device.gd", "pipalo_joystick.gd", "pipalo_button.gd", "pipalo_safe_area.gd",
			"pipalo_touch_control.gd", "LICENSE.md"]:
		check(FileAccess.file_exists("res://addons/pipalo_lite/" + f), "missing " + f)
	var c := ConfigFile.new()
	c.load("res://addons/pipalo_lite/plugin.cfg")
	eq(c.get_value("plugin", "version"), "1.0.0", "version")
	eq(c.get_value("plugin", "author"), "PN Scripts", "author")
