## Estado de ataque do Crow
## Mergulha até o jogador, ativa o hitbox no frame de impacto e retorna ao voo
extends NodeState

var enemy: Crow
var controle_de_animacao_ativo: bool = true

var _elapsed: float = 0.0
var _hitbox_active: bool = false
var _attack_target: Vector2 = Vector2.ZERO


func _ready() -> void:
	if EventBus:
		EventBus.player_died.connect(_on_player_died)


func _on_enter() -> void:
	enemy = owner as Crow
	if enemy == null:
		return

	_elapsed = 0.0
	_hitbox_active = false
	enemy.last_attack_time = Time.get_ticks_msec() / 1000.0
	enemy.disable_hit_box()

	var direction_to_player := Vector2.DOWN
	if enemy.player:
		direction_to_player = enemy.player.global_position - enemy.global_position
		_attack_target = enemy.player.global_position
	else:
		_attack_target = enemy.global_position

	enemy.play_attack_animation(direction_to_player)

	var sfx := enemy.get_node_or_null("SFXComponent") as SFXComponent
	if sfx:
		sfx.attack_triggered.emit()


func _on_process(delta: float) -> void:
	if enemy == null or enemy.is_dead:
		return
	if enemy.is_retreating:
		transition.emit("fly")
		return

	_elapsed += delta

	if not _hitbox_active and _elapsed >= enemy.attack_hit_delay:
		enemy.enable_hit_box()
		_hitbox_active = true
	elif _hitbox_active and _elapsed >= enemy.attack_hit_delay + enemy.attack_hit_duration:
		enemy.disable_hit_box()
		_hitbox_active = false

	if _elapsed >= enemy.attack_total_duration:
		transition.emit("fly")


func _on_physics_process(_delta: float) -> void:
	if enemy == null or enemy.is_dead or enemy.is_retreating:
		return
	if not controle_de_animacao_ativo:
		return

	var distance_to_target := enemy.global_position.distance_to(_attack_target)
	if distance_to_target > 4.0:
		enemy.velocity = enemy.global_position.direction_to(_attack_target) * enemy.attack_dive_speed
	else:
		enemy.velocity = Vector2.ZERO
	enemy.move_and_slide()


func _on_exit() -> void:
	if enemy == null:
		return
	enemy.disable_hit_box()
	enemy.hitbox_offset = Vector2.ZERO


func _on_player_died() -> void:
	controle_de_animacao_ativo = false
