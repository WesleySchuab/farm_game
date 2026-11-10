## Estado de voo do Crow
## Alterna entre pontos distantes e próximos do jogador (sobrevoo),
## atacando de vez em quando ao passar perto.
extends NodeState

var enemy: Crow
var controle_de_animacao_ativo: bool = true

var _waypoint_offset: Vector2 = Vector2.ZERO
var _going_far: bool = true
var _waypoint_time: float = 0.0


func _ready() -> void:
	if EventBus:
		EventBus.player_died.connect(_on_player_died)


func _on_enter() -> void:
	enemy = owner as Crow
	if enemy == null:
		return

	enemy.hitbox_offset = Vector2.ZERO
	enemy.disable_hit_box()

	# Depois de atacar, o corvo recua para longe antes de passar de novo
	_pick_waypoint(true)

	# Durante o spawn a sprite é controlada pelo PortalSpawnComponent
	if not enemy._is_spawning:
		enemy.play_fly_animation(Vector2.RIGHT)


func _on_process(_delta: float) -> void:
	if enemy == null or enemy.is_dead or enemy._is_spawning:
		return
	if enemy.is_retreating:
		enemy.play_flee_animation()
		return
	if enemy._post_spawn_cooldown > 0.0:
		return
	enemy.play_fly_animation(enemy.enemy_direction)


func _on_physics_process(delta: float) -> void:
	if enemy == null or enemy.is_dead or enemy.player == null:
		return
	if not controle_de_animacao_ativo or enemy._is_spawning:
		return

	if enemy.is_retreating:
		_move_away()
		return

	_waypoint_time += delta
	var target_position := enemy.player.global_position + _waypoint_offset
	var direction := enemy.global_position.direction_to(target_position)
	var reached := enemy.global_position.distance_to(target_position) <= enemy.flyby_arrival_distance

	if direction != Vector2.ZERO:
		enemy.enemy_direction = direction
		enemy.set_facing(direction)

	enemy.velocity = direction * enemy.flight_speed
	enemy.move_and_slide()

	if reached or _waypoint_time >= enemy.flyby_waypoint_timeout:
		_pick_waypoint(not _going_far)


func _on_next_transitions() -> void:
	if enemy == null:
		enemy = owner as Crow

	if enemy == null or enemy.is_dead or enemy.player == null:
		return
	if not controle_de_animacao_ativo or enemy._is_spawning or enemy.is_retreating:
		return
	if enemy._post_spawn_cooldown > 0.0:
		return
	# Só ataca quando está se aproximando do jogador
	if _going_far:
		return

	var time_since_attack := Time.get_ticks_msec() / 1000.0 - enemy.last_attack_time
	if enemy.get_distance_to_player() <= enemy.attack_distance and time_since_attack >= enemy.attack_cooldown:
		transition.emit("attack")


func _pick_waypoint(far: bool) -> void:
	_going_far = far
	_waypoint_offset = enemy.get_flyby_offset(far)
	_waypoint_time = 0.0


func _move_away() -> void:
	var away := Vector2.UP
	if enemy.player:
		away = enemy.global_position - enemy.player.global_position
		if away == Vector2.ZERO:
			away = Vector2.UP
		away = (away.normalized() + Vector2(0.0, -0.6)).normalized()

	enemy.enemy_direction = away
	enemy.set_facing(away)
	enemy.velocity = away * enemy.retreat_speed
	enemy.move_and_slide()


func _on_player_died() -> void:
	controle_de_animacao_ativo = false
