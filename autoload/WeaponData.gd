extends Node
## 무기 데이터베이스 - PUBG 무기 스탯 + 반동 패턴 파라미터
## 반동 수치는 공식 데이터가 아닌, 커뮤니티에 알려진 무기별 특성(수직/수평 반동 세기,
## 연사 시 악화되는 정도)을 바탕으로 근사 구현한 값입니다.

const CATEGORY_NAMES := {
	"AR": "돌격소총 (AR)",
	"DMR": "지정사수소총 (DMR)",
	"SMG": "기관단총 (SMG)",
	"LMG": "경기관총 (LMG)",
	"SR": "저격소총 (SR)",
	"PISTOL": "권총 (Pistol)",
	"SHOTGUN": "샷건 (Shotgun)",
}

const CATEGORY_ORDER := ["AR", "DMR", "SMG", "LMG", "SR", "PISTOL", "SHOTGUN"]

# recoil 필드 설명:
#   vert_base   : 첫 몇 발의 기본 수직 반동 (도/발)
#   vert_growth : 연사가 지속될수록 수직 반동이 커지는 비율
#   vert_cap    : 수직 반동 배율 상한
#   horiz_amp   : 수평 흔들림 폭 (도)
#   horiz_bias  : 총기 고유의 편향 방향 (-1 좌 ~ +1 우)
#   horiz_growth: 연사 지속시 수평 흔들림 증가율
#   kick_first  : 첫 발 반동 배율 (점사/저격 무기는 큼)
#   sustained   : true면 연사할수록 패턴이 누적/악화됨 (자동사격 무기)
const WEAPONS := {
	# ---------------- 돌격소총 (AR) ----------------
	"akm": {"name": "AKM", "category": "AR", "damage": 47, "rpm": 600, "magazine": 40,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.95, "vert_growth": 0.09, "vert_cap": 2.6, "horiz_amp": 0.65, "horiz_bias": 0.3, "horiz_growth": 0.10, "kick_first": 1.3, "sustained": true}},
	"m416": {"name": "M416", "category": "AR", "damage": 40, "rpm": 700, "magazine": 40,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.55, "vert_growth": 0.045, "vert_cap": 1.8, "horiz_amp": 0.25, "horiz_bias": 0.0, "horiz_growth": 0.05, "kick_first": 1.1, "sustained": true}},
	"scarl": {"name": "SCAR-L", "category": "AR", "damage": 42, "rpm": 625, "magazine": 40,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.5, "vert_growth": 0.04, "vert_cap": 1.7, "horiz_amp": 0.22, "horiz_bias": -0.15, "horiz_growth": 0.045, "kick_first": 1.1, "sustained": true}},
	"m16a4": {"name": "M16A4", "category": "AR", "damage": 43, "rpm": 750, "magazine": 40,
		"fire_modes": ["single", "burst"],
		"recoil": {"vert_base": 0.6, "vert_growth": 0.02, "vert_cap": 1.3, "horiz_amp": 0.2, "horiz_bias": 0.0, "horiz_growth": 0.02, "kick_first": 1.2, "sustained": false}},
	"groza": {"name": "Groza", "category": "AR", "damage": 47, "rpm": 750, "magazine": 40,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.85, "vert_growth": 0.06, "vert_cap": 2.1, "horiz_amp": 0.4, "horiz_bias": 0.2, "horiz_growth": 0.07, "kick_first": 1.2, "sustained": true}},
	"auga3": {"name": "AUG A3", "category": "AR", "damage": 40, "rpm": 650, "magazine": 40,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.5, "vert_growth": 0.035, "vert_cap": 1.6, "horiz_amp": 0.22, "horiz_bias": 0.1, "horiz_growth": 0.04, "kick_first": 1.1, "sustained": true}},
	"berylm762": {"name": "베릴 M762", "category": "AR", "damage": 44, "rpm": 700, "magazine": 40,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 1.0, "vert_growth": 0.1, "vert_cap": 2.7, "horiz_amp": 0.5, "horiz_bias": -0.35, "horiz_growth": 0.11, "kick_first": 1.3, "sustained": true}},
	"qbz95": {"name": "QBZ95", "category": "AR", "damage": 42, "rpm": 750, "magazine": 40,
		"fire_modes": ["single", "burst", "auto"],
		"recoil": {"vert_base": 0.55, "vert_growth": 0.05, "vert_cap": 1.9, "horiz_amp": 0.28, "horiz_bias": 0.15, "horiz_growth": 0.05, "kick_first": 1.15, "sustained": true}},
	"g36c": {"name": "G36C", "category": "AR", "damage": 43, "rpm": 700, "magazine": 40,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.5, "vert_growth": 0.04, "vert_cap": 1.7, "horiz_amp": 0.24, "horiz_bias": -0.1, "horiz_growth": 0.045, "kick_first": 1.1, "sustained": true}},
	"k2": {"name": "K2", "category": "AR", "damage": 41, "rpm": 620, "magazine": 40,
		"fire_modes": ["single", "burst", "auto"],
		"recoil": {"vert_base": 0.6, "vert_growth": 0.05, "vert_cap": 1.9, "horiz_amp": 0.3, "horiz_bias": 0.1, "horiz_growth": 0.05, "kick_first": 1.15, "sustained": true}},
	"mk47": {"name": "Mk47 Mutant", "category": "AR", "damage": 49, "rpm": 600, "magazine": 30,
		"fire_modes": ["single", "burst"],
		"recoil": {"vert_base": 1.1, "vert_growth": 0.03, "vert_cap": 1.5, "horiz_amp": 0.5, "horiz_bias": 0.25, "horiz_growth": 0.03, "kick_first": 1.4, "sustained": false}},
	"famas": {"name": "FAMAS", "category": "AR", "damage": 39, "rpm": 1000, "magazine": 40,
		"fire_modes": ["single", "burst"],
		"recoil": {"vert_base": 0.5, "vert_growth": 0.02, "vert_cap": 1.3, "horiz_amp": 0.2, "horiz_bias": 0.0, "horiz_growth": 0.02, "kick_first": 1.15, "sustained": false}},

	# ---------------- DMR ----------------
	"sks": {"name": "SKS", "category": "DMR", "damage": 53, "rpm": 600, "magazine": 20,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 1.6, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.5, "horiz_bias": 0.2, "horiz_growth": 0.0, "kick_first": 1.6, "sustained": false}},
	"mini14": {"name": "Mini14", "category": "DMR", "damage": 42, "rpm": 600, "magazine": 30,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 1.2, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.35, "horiz_bias": -0.1, "horiz_growth": 0.0, "kick_first": 1.4, "sustained": false}},
	"slr": {"name": "SLR", "category": "DMR", "damage": 56, "rpm": 600, "magazine": 20,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 1.7, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.55, "horiz_bias": 0.25, "horiz_growth": 0.0, "kick_first": 1.7, "sustained": false}},
	"mk14": {"name": "Mk14 EBR", "category": "DMR", "damage": 61, "rpm": 667, "magazine": 20,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 1.4, "vert_growth": 0.08, "vert_cap": 2.0, "horiz_amp": 0.6, "horiz_bias": 0.3, "horiz_growth": 0.08, "kick_first": 1.8, "sustained": true}},
	"vss": {"name": "VSS", "category": "DMR", "damage": 45, "rpm": 700, "magazine": 20,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.5, "vert_growth": 0.02, "vert_cap": 1.2, "horiz_amp": 0.15, "horiz_bias": 0.0, "horiz_growth": 0.02, "kick_first": 1.1, "sustained": true}},
	"qbu": {"name": "QBU", "category": "DMR", "damage": 42, "rpm": 600, "magazine": 20,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 1.3, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.4, "horiz_bias": 0.15, "horiz_growth": 0.0, "kick_first": 1.5, "sustained": false}},
	"svd": {"name": "드라구노프 (SVD)", "category": "DMR", "damage": 53, "rpm": 600, "magazine": 20,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 1.6, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.5, "horiz_bias": -0.2, "horiz_growth": 0.0, "kick_first": 1.6, "sustained": false}},
	"mk12": {"name": "Mk12", "category": "DMR", "damage": 43, "rpm": 600, "magazine": 20,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 1.1, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.3, "horiz_bias": 0.1, "horiz_growth": 0.0, "kick_first": 1.3, "sustained": false}},

	# ---------------- SMG ----------------
	"ump45": {"name": "UMP45", "category": "SMG", "damage": 41, "rpm": 674, "magazine": 35,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.35, "vert_growth": 0.03, "vert_cap": 1.5, "horiz_amp": 0.18, "horiz_bias": 0.0, "horiz_growth": 0.03, "kick_first": 1.1, "sustained": true}},
	"vector": {"name": "Vector", "category": "SMG", "damage": 31, "rpm": 1090, "magazine": 33,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.3, "vert_growth": 0.07, "vert_cap": 1.9, "horiz_amp": 0.22, "horiz_bias": 0.15, "horiz_growth": 0.07, "kick_first": 1.1, "sustained": true}},
	"uzi": {"name": "Micro UZI", "category": "SMG", "damage": 26, "rpm": 1200, "magazine": 35,
		"fire_modes": ["auto"],
		"recoil": {"vert_base": 0.4, "vert_growth": 0.08, "vert_cap": 2.0, "horiz_amp": 0.35, "horiz_bias": -0.2, "horiz_growth": 0.08, "kick_first": 1.15, "sustained": true}},
	"tommygun": {"name": "톰슨 (Tommy Gun)", "category": "SMG", "damage": 40, "rpm": 750, "magazine": 50,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.55, "vert_growth": 0.05, "vert_cap": 1.7, "horiz_amp": 0.3, "horiz_bias": 0.1, "horiz_growth": 0.05, "kick_first": 1.15, "sustained": true}},
	"bizon": {"name": "PP-19 비존", "category": "SMG", "damage": 38, "rpm": 700, "magazine": 53,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.4, "vert_growth": 0.04, "vert_cap": 1.6, "horiz_amp": 0.2, "horiz_bias": 0.0, "horiz_growth": 0.04, "kick_first": 1.1, "sustained": true}},
	"p90": {"name": "P90", "category": "SMG", "damage": 35, "rpm": 1000, "magazine": 50,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.3, "vert_growth": 0.035, "vert_cap": 1.5, "horiz_amp": 0.16, "horiz_bias": 0.0, "horiz_growth": 0.035, "kick_first": 1.05, "sustained": true}},
	"mp5k": {"name": "MP5K", "category": "SMG", "damage": 32, "rpm": 850, "magazine": 40,
		"fire_modes": ["single", "burst", "auto"],
		"recoil": {"vert_base": 0.3, "vert_growth": 0.03, "vert_cap": 1.4, "horiz_amp": 0.15, "horiz_bias": 0.0, "horiz_growth": 0.03, "kick_first": 1.05, "sustained": true}},

	# ---------------- LMG ----------------
	"m249": {"name": "M249", "category": "LMG", "damage": 41, "rpm": 800, "magazine": 150,
		"fire_modes": ["auto"],
		"recoil": {"vert_base": 0.6, "vert_growth": 0.055, "vert_cap": 2.2, "horiz_amp": 0.4, "horiz_bias": 0.2, "horiz_growth": 0.05, "kick_first": 1.2, "sustained": true}},
	"dp28": {"name": "DP-28", "category": "LMG", "damage": 52, "rpm": 550, "magazine": 47,
		"fire_modes": ["auto"],
		"recoil": {"vert_base": 0.85, "vert_growth": 0.08, "vert_cap": 2.4, "horiz_amp": 0.5, "horiz_bias": -0.25, "horiz_growth": 0.08, "kick_first": 1.25, "sustained": true}},
	"mg3": {"name": "MG3", "category": "LMG", "damage": 42, "rpm": 1200, "magazine": 75,
		"fire_modes": ["auto"],
		"recoil": {"vert_base": 0.75, "vert_growth": 0.1, "vert_cap": 2.8, "horiz_amp": 0.6, "horiz_bias": 0.3, "horiz_growth": 0.11, "kick_first": 1.3, "sustained": true}},

	# ---------------- 저격소총 (SR, 볼트/레버액션) ----------------
	"kar98k": {"name": "Kar98k", "category": "SR", "damage": 79, "rpm": 32, "magazine": 5,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 3.2, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.4, "horiz_bias": 0.0, "horiz_growth": 0.0, "kick_first": 1.0, "sustained": false}},
	"m24": {"name": "M24", "category": "SR", "damage": 75, "rpm": 33, "magazine": 7,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 3.6, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.4, "horiz_bias": 0.0, "horiz_growth": 0.0, "kick_first": 1.0, "sustained": false}},
	"awm": {"name": "AWM", "category": "SR", "damage": 105, "rpm": 32, "magazine": 7,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 4.5, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.5, "horiz_bias": 0.0, "horiz_growth": 0.0, "kick_first": 1.0, "sustained": false}},
	"win94": {"name": "Win94", "category": "SR", "damage": 66, "rpm": 150, "magazine": 8,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 2.2, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.35, "horiz_bias": 0.0, "horiz_growth": 0.0, "kick_first": 1.0, "sustained": false}},
	"amr": {"name": "AMR (Lynx)", "category": "SR", "damage": 118, "rpm": 180, "magazine": 5,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 6.0, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.6, "horiz_bias": 0.0, "horiz_growth": 0.0, "kick_first": 1.0, "sustained": false}},

	# ---------------- 권총 (Pistol) ----------------
	"p92": {"name": "P92", "category": "PISTOL", "damage": 34, "rpm": 350, "magazine": 20,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 0.7, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.25, "horiz_bias": 0.0, "horiz_growth": 0.0, "kick_first": 1.2, "sustained": false}},
	"p1911": {"name": "P1911", "category": "PISTOL", "damage": 42, "rpm": 300, "magazine": 12,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 0.8, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.25, "horiz_bias": 0.0, "horiz_growth": 0.0, "kick_first": 1.2, "sustained": false}},
	"r45": {"name": "R45 (Deagle)", "category": "PISTOL", "damage": 65, "rpm": 240, "magazine": 10,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 1.8, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.5, "horiz_bias": 0.2, "horiz_growth": 0.0, "kick_first": 1.5, "sustained": false}},
	"skorpion": {"name": "스콜피온", "category": "PISTOL", "damage": 22, "rpm": 1200, "magazine": 40,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.5, "vert_growth": 0.09, "vert_cap": 2.0, "horiz_amp": 0.4, "horiz_bias": -0.2, "horiz_growth": 0.09, "kick_first": 1.15, "sustained": true}},
	"p18c": {"name": "P18C", "category": "PISTOL", "damage": 23, "rpm": 1000, "magazine": 25,
		"fire_modes": ["single", "auto"],
		"recoil": {"vert_base": 0.5, "vert_growth": 0.08, "vert_cap": 1.9, "horiz_amp": 0.35, "horiz_bias": 0.15, "horiz_growth": 0.08, "kick_first": 1.15, "sustained": true}},

	# ---------------- 샷건 (Shotgun) ----------------
	"s12k": {"name": "S12K", "category": "SHOTGUN", "damage": 22, "rpm": 300, "magazine": 11,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 2.0, "vert_growth": 0.03, "vert_cap": 1.3, "horiz_amp": 0.4, "horiz_bias": 0.0, "horiz_growth": 0.03, "kick_first": 1.3, "sustained": true}},
	"s1897": {"name": "S1897", "category": "SHOTGUN", "damage": 26, "rpm": 100, "magazine": 5,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 2.6, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.45, "horiz_bias": 0.0, "horiz_growth": 0.0, "kick_first": 1.4, "sustained": false}},
	"s686": {"name": "S686", "category": "SHOTGUN", "damage": 23, "rpm": 150, "magazine": 2,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 2.8, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.5, "horiz_bias": 0.0, "horiz_growth": 0.0, "kick_first": 1.4, "sustained": false}},
	"dbs": {"name": "DBS", "category": "SHOTGUN", "damage": 26, "rpm": 200, "magazine": 14,
		"fire_modes": ["single"],
		"recoil": {"vert_base": 2.3, "vert_growth": 0.0, "vert_cap": 1.0, "horiz_amp": 0.45, "horiz_bias": 0.0, "horiz_growth": 0.0, "kick_first": 1.35, "sustained": false}},
}

const DEFAULT_WEAPON := "m416"

## 카테고리별 조준(ADS) 시 FOV 배율 - 낮을수록 더 확대됨
const ADS_FOV_MULT := {
	"AR": 0.78,
	"DMR": 0.55,
	"SMG": 0.82,
	"LMG": 0.8,
	"SR": 0.35,
	"PISTOL": 0.88,
	"SHOTGUN": 0.88,
}


func get_ads_fov_mult(weapon_id: String) -> float:
	var w := get_weapon(weapon_id)
	var mult: float = ADS_FOV_MULT.get(w["category"], 0.8)
	return mult


## 실제 체감 연사력이 너무 빠르다는 피드백으로 전체 연사 속도를 낮추는 배율
const GLOBAL_RPM_SCALE := 0.72


func get_effective_rpm(weapon_id: String) -> int:
	var w := get_weapon(weapon_id)
	return int(round(float(w["rpm"]) * GLOBAL_RPM_SCALE))


func get_fire_interval(weapon_id: String) -> float:
	return 60.0 / float(get_effective_rpm(weapon_id))


## 카테고리별 기본 히프파이어(무조준 사격) 탄퍼짐 - 클수록 덜 정확함
const BASE_HIP_SPREAD_DEG := {
	"AR": 0.9,
	"DMR": 0.6,
	"SMG": 0.8,
	"LMG": 1.4,
	"SR": 2.5,
	"PISTOL": 0.7,
	"SHOTGUN": 1.0,
}


func get_base_spread(weapon_id: String) -> float:
	var w := get_weapon(weapon_id)
	var spread: float = BASE_HIP_SPREAD_DEG.get(w["category"], 0.9)
	return spread * GLOBAL_HIP_SPREAD_SCALE


func get_ids_by_category(category: String) -> Array:
	var ids := []
	for id in WEAPONS.keys():
		if WEAPONS[id]["category"] == category:
			ids.append(id)
	return ids


func get_weapon(id: String) -> Dictionary:
	return WEAPONS.get(id, WEAPONS[DEFAULT_WEAPON])


## 결정적(deterministic)이지만 무작위처럼 보이는 값을 (weapon_id, shot_index, salt)로부터 생성.
## 매 실행마다 같은 총은 같은 패턴을 그리므로 반동 패턴을 "외워서" 연습할 수 있다.
func _pseudo_rand(seed_val: float, i: int, salt: float) -> float:
	var x := sin(seed_val * 12.9898 + float(i) * 78.233 + salt) * 43758.5453
	return x - floor(x)


func _weapon_seed(weapon_id: String) -> float:
	return float(weapon_id.hash() % 100000)


## 전체 무기 수직 반동 세기를 한번에 조절하는 배율 (튜닝용)
const GLOBAL_VERT_SCALE := 0.5
## 전체 힙파이어 탄퍼짐 배율 (튜닝용) - 낮을수록 정확
const GLOBAL_HIP_SPREAD_SCALE := 0.35
## 수직 반동에 섞이는 흔들림 크기 (climb 값 대비 비율) - 가끔 살짝 아래로도 튀게 함
const VERT_WOBBLE_MULT := 1.15


## 특정 발사(shot_index, 0부터 시작)에서 카메라에 가할 반동을 (pitch_deg, yaw_deg)로 반환.
## pitch는 대체로 양수(위로 튐)이지만, 흔들림(wobble)으로 인해 가끔 소폭 음수(아래)가 나올 수 있음.
func get_shot_recoil(weapon_id: String, shot_index: int) -> Vector2:
	var w := get_weapon(weapon_id)
	var r: Dictionary = w["recoil"]
	var seed_v := _weapon_seed(weapon_id)

	var growth_i: float = min(shot_index, 8)
	var vert_mult: float = 1.0
	if r["sustained"]:
		vert_mult = clamp(1.0 + growth_i * r["vert_growth"], 1.0, r["vert_cap"])
	var climb: float = r["vert_base"] * vert_mult * GLOBAL_VERT_SCALE
	var wobble_amp: float = climb * VERT_WOBBLE_MULT
	var wobble := (_pseudo_rand(seed_v, shot_index, 7.0) * 2.0 - 1.0) * wobble_amp
	var vertical: float = climb + wobble

	var horiz_mult: float = 1.0
	if r["sustained"]:
		horiz_mult = clamp(1.0 + growth_i * r["horiz_growth"], 1.0, r["vert_cap"])
	var jitter := (_pseudo_rand(seed_v, shot_index, 1.0) * 2.0 - 1.0)
	var horizontal: float = r["horiz_amp"] * horiz_mult * jitter + r["horiz_bias"] * horiz_mult * 0.3

	if shot_index == 0:
		vertical *= r["kick_first"]
		horizontal *= r["kick_first"]

	return Vector2(vertical, horizontal)
