extends Control
## 무기 카테고리별 실루엣 아이콘을 절차적으로 그린다 (원본 픽토그램, 실총 이미지 아님).

var category: String = "AR"
var icon_color: Color = Color(0.88, 0.9, 0.95)

const SHAPES := {
	"AR": [
		Rect2(6, 13, 44, 6), Rect2(50, 15, 18, 3), Rect2(2, 12, 8, 5),
		Rect2(18, 19, 6, 11), Rect2(28, 19, 4, 7),
	],
	"DMR": [
		Rect2(6, 13, 44, 6), Rect2(50, 15, 18, 3), Rect2(2, 12, 8, 5),
		Rect2(18, 19, 6, 11), Rect2(28, 19, 4, 7),
		Rect2(24, 6, 14, 5), Rect2(30, 4, 4, 3),
	],
	"SMG": [
		Rect2(10, 13, 28, 6), Rect2(38, 15, 10, 3), Rect2(4, 14, 8, 4),
		Rect2(16, 19, 5, 10), Rect2(26, 19, 4, 8),
	],
	"LMG": [
		Rect2(6, 12, 46, 7), Rect2(52, 14, 16, 4), Rect2(2, 11, 8, 6),
		Rect2(20, 19, 10, 12), Rect2(32, 19, 4, 7),
		Rect2(50, 24, 3, 8), Rect2(58, 24, 3, 8),
	],
	"SR": [
		Rect2(10, 14, 50, 4), Rect2(2, 12, 10, 6), Rect2(18, 19, 5, 10),
		Rect2(28, 19, 4, 7), Rect2(20, 4, 22, 5), Rect2(26, 2, 6, 3),
		Rect2(45, 18, 4, 4),
	],
	"PISTOL": [
		Rect2(10, 14, 26, 6), Rect2(30, 15, 8, 3), Rect2(14, 19, 8, 12),
	],
	"SHOTGUN": [
		Rect2(8, 13, 46, 4), Rect2(12, 18, 30, 4), Rect2(2, 12, 10, 6),
		Rect2(30, 22, 5, 8),
	],
}


func _ready() -> void:
	custom_minimum_size = Vector2(72, 32)


func _draw() -> void:
	var rects: Array = SHAPES.get(category, SHAPES["AR"])
	for r in rects:
		draw_rect(r, icon_color)
