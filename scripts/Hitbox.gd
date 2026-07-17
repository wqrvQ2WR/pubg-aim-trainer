extends Area3D
## 표적의 머리/몸통 판정 영역. 실제 데미지 계산은 부모 Target에 위임한다.

var target: Node3D
var part: String = "body"


func take_hit(damage: int, hit_pos: Vector3) -> bool:
	if target and target.has_method("register_hit"):
		return target.register_hit(damage, part, hit_pos)
	return false
