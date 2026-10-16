@tool
@icon("res://addons/pipalo_lite/icons/safe_area.svg")
class_name PipaloLiteSafeArea
extends MarginContainer
## Keeps its children out of notches, rounded corners and system bars (Pipalo Lite by PN Scripts, MIT).
## Put your touch controls inside a full-rect PipaloLiteSafeArea; on desktop the margins are just
## the minimum margin.

## Margin used everywhere, added to the system's safe area.
@export var minimum_margin := 24:
	set(v):
		minimum_margin = v
		update_margins()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(update_margins)
	update_margins()


## Recomputes the margins from DisplayServer.get_display_safe_area().
func update_margins() -> void:
	if not is_inside_tree():
		return
	var insets := safe_insets()
	add_theme_constant_override("margin_left", minimum_margin + int(insets.position.x))
	add_theme_constant_override("margin_top", minimum_margin + int(insets.position.y))
	add_theme_constant_override("margin_right", minimum_margin + int(insets.size.x))
	add_theme_constant_override("margin_bottom", minimum_margin + int(insets.size.y))


## Left/top in position and right/bottom in size, in viewport pixels.
func safe_insets() -> Rect2:
	# The web display server has no safe area (it prints "Not supported" errors); the browser keeps
	# the page inside the safe area unless the page opts out with viewport-fit=cover.
	if Engine.is_editor_hint() or DisplayServer.get_name() == "headless" or OS.has_feature("web"):
		return Rect2()
	var screen := DisplayServer.screen_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if screen.x <= 0 or safe.size.x <= 0:
		return Rect2()
	var vp := get_viewport_rect().size
	var sx := vp.x / screen.x
	var sy := vp.y / screen.y
	return Rect2(safe.position.x * sx, safe.position.y * sy,
		(screen.x - safe.end.x) * sx, (screen.y - safe.end.y) * sy)
