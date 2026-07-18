extends Node3D
## N키로 켜고 끄는 AI 대전 모드: 봇 스폰/디스폰과 킬 스코어를 관리한다.

signal score_changed(player_kills: int, ai_kills: int)
signal mode_changed(active: bool)

const AIBotScript := preload("res://scripts/AIBot.gd")

const SPAWN_POINTS := [
	Vector3(-10, 0, -30), Vector3(10, 0, -30), Vector3(0, 0, -45),
	Vector3(-14, 0, -60), Vector3(14, 0, -60), Vector3(0, 0, -20),
	Vector3(-6, 0, -75), Vector3(6, 0, -75),
]

var player: Node = null
var ai_bot: Node3D = null
var mode_active: bool = false
var player_kills: int = 0
var ai_kills: int = 0


func _ready() -> void:
	if player:
		player.died.connect(_on_player_died)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("duel_toggle"):
		toggle_mode()


func toggle_mode() -> void:
	if mode_active:
		stop_mode()
	else:
		start_mode()


func start_mode() -> void:
	mode_active = true
	player_kills = 0
	ai_kills = 0
	score_changed.emit(player_kills, ai_kills)
	_spawn_bot()
	mode_changed.emit(true)


func stop_mode() -> void:
	mode_active = false
	if ai_bot:
		ai_bot.queue_free()
		ai_bot = null
	mode_changed.emit(false)


func _spawn_bot() -> void:
	if ai_bot:
		ai_bot.queue_free()
		ai_bot = null
	var bot := CharacterBody3D.new()
	bot.set_script(AIBotScript)
	bot.player = player
	bot.spawn_points = SPAWN_POINTS
	add_child(bot)
	bot.ai_died.connect(_on_ai_died)
	bot.spawn_at(SPAWN_POINTS[randi() % SPAWN_POINTS.size()])
	ai_bot = bot


func _on_ai_died() -> void:
	if not mode_active:
		return
	player_kills += 1
	score_changed.emit(player_kills, ai_kills)


func _on_player_died() -> void:
	if not mode_active:
		return
	ai_kills += 1
	score_changed.emit(player_kills, ai_kills)
