extends Node2D
## Pipalo Lite demo: a small runner that reads ordinary input actions. Keyboard, gamepad and the
## touch controls all drive the same actions. On a desktop, click and drag to try the touch
## controls (the project has Emulate Touch From Mouse on). Copyright (c) 2026 PN Scripts. MIT.

@onready var device_label: Label = $UI/SafeArea/Layout/Device


func _ready() -> void:
	PipaloLite.device_changed.connect(func(_k, _f): _show_device())
	_show_device()


func _show_device() -> void:
	var text := "Device: " + PipaloLite.kind
	if PipaloLite.kind == "gamepad":
		text += " (%s)" % PipaloLite.family
	text += "\n" + ("Drag on the left to move, tap Jump and Dash" if PipaloLite.kind == "touch" else "A/D or arrows: move   Space: jump   Shift: dash")
	device_label.text = text
