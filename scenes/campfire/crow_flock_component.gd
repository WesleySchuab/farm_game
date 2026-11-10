class_name CrowFlockComponent
extends Node

## Gera bandos de corvos enquanto a fogueira estiver apagada.
## Deve ficar como filho da fogueira; os corvos são adicionados ao nível.

const CROW_SCENE: PackedScene = preload("res://scenes/characters/enemy/crow.tscn")

## Quantidade mínima e máxima de corvos por onda
@export var min_crows_per_wave: int = 1
@export var max_crows_per_wave: int = 8

## Limite de corvos vivos ao mesmo tempo
@export var max_alive_crows: int = 8

## Distância radial (em px) em que os corvos surgem ao redor do player
@export var spawn_radius_min: float = 420.0
@export var spawn_radius_max: float = 620.0

## Altura extra em que os corvos surgem acima do player
@export var spawn_height: float = 120.0

## Tempo até a primeira onda após a fogueira apagar
@export var first_wave_delay: float = 20.0

## Tempo até a próxima onda enquanto a fogueira continuar apagada
@export var respawn_delay: float = 18.0

## Intervalo de ataque sorteado para cada corvo (segundos)
@export var attack_cooldown_min: float = 19.0
@export var attack_cooldown_max: float = 19.0

## Onde os corvos são adicionados (padrão: o nível, irmão da fogueira)
@export var crow_parent_path: NodePath = ^"../.."

var _campfire_lit: bool = true
var _player_died: bool = false
var _active_crows: Array[Crow] = []
var _wave_timer: float = 0.0
var _next_wave_delay: float = 0.0


func _ready() -> void:
	EventBus.campfire_state_changed.connect(_on_campfire_state_changed)
	EventBus.player_died.connect(_on_player_died)
	set_process(false)


func _process(delta: float) -> void:
	_prune_crows()
	if _campfire_lit or _player_died:
		return
	if _active_crows.size() >= max_alive_crows:
		_wave_timer = 0.0
		return

	_wave_timer += delta
	if _wave_timer >= _next_wave_delay:
		_spawn_wave()


func _on_campfire_state_changed(is_lit: bool) -> void:
	_campfire_lit = is_lit
	if is_lit:
		set_process(false)
		_wave_timer = 0.0
		_dismiss_crows()
		print("🦅 [CROW FLOCK] Fogueira acesa: os corvos vão embora.")
		return

	_player_died = false
	set_process(true)
	_wave_timer = 0.0
	_next_wave_delay = first_wave_delay
	print("🦅 [CROW FLOCK] Fogueira apagada: bandos de corvos se aproximando...")


func _on_player_died() -> void:
	_player_died = true
	set_process(false)
	_dismiss_crows()


func _spawn_wave() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var crow_parent := get_node_or_null(crow_parent_path)
	if player == null or crow_parent == null:
		return

	var available: int = max_alive_crows - _active_crows.size()
	var count: int = mini(randi_range(min_crows_per_wave, max_crows_per_wave), available)
	if count <= 0:
		return

	for i in count:
		var crow := CROW_SCENE.instantiate() as Crow
		crow_parent.add_child(crow)
		crow.global_position = _get_spawn_position(player)
		crow.skip_spawn_portal()
		# Corvos de sobrevoo não precisam colidir com o cenário
		crow.collision_mask = 0
		crow.attack_cooldown = randf_range(attack_cooldown_min, attack_cooldown_max)
		_active_crows.append(crow)

	_wave_timer = 0.0
	_next_wave_delay = respawn_delay
	print("🦅 [CROW FLOCK] Onda de ", count, " corvo(s) surgiu! Vivos: ", _active_crows.size())


func _get_spawn_position(player: Node2D) -> Vector2:
	var angle := randf_range(0.0, TAU)
	var radius := randf_range(spawn_radius_min, spawn_radius_max)
	return player.global_position + Vector2(
		cos(angle) * radius,
		-spawn_height + sin(angle) * 40.0
	)


func _prune_crows() -> void:
	for i in range(_active_crows.size() - 1, -1, -1):
		var crow := _active_crows[i]
		if not is_instance_valid(crow) or crow.is_dead:
			_active_crows.remove_at(i)


func _dismiss_crows() -> void:
	for crow in _active_crows:
		if is_instance_valid(crow):
			crow.start_retreat()
	_active_crows.clear()
