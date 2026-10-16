extends Node
## Test-only probe (not shipped): prints the player's state for the browser console.
var t := 0.0
func _process(delta: float) -> void:
	t += delta
	if t < 0.2:
		return
	t = 0.0
	var p := get_tree().current_scene.get_node_or_null("Player") as CharacterBody2D
	if p:
		print("PROBE x=%d y=%d vy=%d device=%s jump=%s" % [p.position.x, p.position.y, p.velocity.y, PipaloLite.kind, Input.is_action_pressed("jump")])
