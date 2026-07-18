extends Node3D
## N키로 켜고 끄는 AI 대전 모드: 봇 스폰/디스폰과 킬 스코어를 관리한다.

signal score_changed(player_kills: int, ai_kills: int)
signal mode_changed(active: bool)
signal difficulty_changed(level: String)

const AIBotScript := preload("res://scripts/AIBot.gd")

var player: Node = null
var arena: Node3D = null
var ai_bot: Node3D = null
var mode_active: bool = false
var player_kills: int = 0
var ai_kills: int = 0
var difficulty: String = "normal"


func _ready() -> void:
	if player:
		player.died.connect(_on_player_died)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("duel_toggle"):
		toggle_mode()


func set_difficulty(level: String) -> void:
	difficulty = level
	if ai_bot:
		ai_bot.set_difficulty(level)
	difficulty_changed.emit(level)


func toggle_mode() -> void:
	if mode_active:
		stop_mode()
	else:
		start_mode()


func start_mode() -> void:
	if not arena:
		return
	mode_active = true
	player_kills = 0
	ai_kills = 0
	score_changed.emit(player_kills, ai_kills)

	if player:
		player.set_terrain_height_provider(arena)
		player.set_temp_spawn(arena.player_start)
		player.teleport_to(arena.player_start)
		player.heal_full()

	_spawn_bot()
	mode_changed.emit(true)


func stop_mode() -> void:
	mode_active = false
	if ai_bot:
		ai_bot.queue_free()
		ai_bot = null
	if player:
		player.set_terrain_height_provider(null)
		player.clear_temp_spawn()
		player.teleport_to(player.spawn_position)
		player.heal_full()
	mode_changed.emit(false)


func _spawn_bot() -> void:
	if ai_bot:
		ai_bot.queue_free()
		ai_bot = null
	var points: Array = arena.spawn_points
	var bot := CharacterBody3D.new()
	bot.set_script(AIBotScript)
	bot.player = player
	bot.spawn_points = points
	bot.terrain_provider = arena
	add_child(bot)
	bot.set_difficulty(difficulty)
	bot.ai_died.connect(_on_ai_died)
	bot.spawn_at(points[randi() % points.size()])
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
