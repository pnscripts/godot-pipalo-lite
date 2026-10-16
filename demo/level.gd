extends StaticBody2D
## The demo's floor and ledges, drawn and given collision from one list.

const BLOCKS := [Rect2(-400, 600, 2080, 400), Rect2(180, 470, 220, 26), Rect2(860, 430, 240, 26), Rect2(520, 330, 200, 26)]


func _ready() -> void:
	for r in BLOCKS:
		var s := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		s.shape = shape
		s.position = r.get_center()
		add_child(s)


func _draw() -> void:
	for i in BLOCKS.size():
		var r: Rect2 = BLOCKS[i]
		draw_rect(r, Color(0.2, 0.22, 0.28) if i == 0 else Color(0.27, 0.3, 0.38))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color(0.56, 0.94, 0.6, 0.8))
	for x in range(-400, 1700, 80):
		draw_line(Vector2(x, 0), Vector2(x, 600), Color(1, 1, 1, 0.025), 1.0)
