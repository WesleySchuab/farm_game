## Estado de voo do Crow
## Circula o jogador sempre acima dele, exceto durante o ataque
extends NodeState

var enemy: Crow
var controle_de_animacao_ativo: bool = true

var _orbit_angle: float = 0.0


func _ready() -> void:
	if EventBus:
		EventBus.player_died.connect(_on_player_died)


func _on_enter() -> void:
	enemy = owner as Crow
	if enemy == null:
		return

	enemy.hitbox_offset = Vector2.ZERO
	enemy.disable_hit_box()

	# Durante o spawn a sprite é controlada pelo PortalSpawnComponent
	if not enemy._is_spawning:
		enemy.play_fly_animation(Vector2.RIGHT)


func _on_process(_delta: float) -> void:
	if enemy == null or enemy.is_dead or enemy._is_spawning:
		return
	if enemy._post_spawn_cooldown > 0.0:
		return
	enemy.play_fly_animation(enemy.enemy_direction)


func _on_physics_process(delta: float) -> void:
	if enemy == null or enemy.is_dead:
		return
	if not controle_de_animacao_ativo or enemy.player == null:
		return
	if enemy._is_spawning:
		return

	_orbit_angle = fposmod(_orbit_angle + enemy.orbit_speed * delta, TAU)
	var target_position := enemy.get_orbit_position(_orbit_angle)
	var direction := enemy.global_position.direction_to(target_position)

	if direction != Vector2.ZERO:
		enemy.enemy_direction = direction
		enemy.set_facing(direction)

	enemy.velocity = direction * enemy.flight_speed
	enemy.move_and_slide()


func _on_next_transitions() -> void:
	if enemy == null:
		enemy = owner as Crow

	if enemy == null or enemy.is_dead or enemy.player == null:
		return
	if not controle_de_animacao_ativo or enemy._is_spawning:
		return
	if enemy._post_spawn_cooldown > 0.0:
		return

	var time_since_attack := Time.get_ticks_msec() / 1000.0 - enemy.last_attack_time
	if enemy.get_distance_to_player() <= enemy.attack_distance and time_since_attack >= enemy.attack_cooldown:
		transition.emit("attack")


func _on_player_died() -> void:
	controle_de_animacao_ativo = false
