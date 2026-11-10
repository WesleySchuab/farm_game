class_name Crow
extends Enemy

## Animações autorais da cena (a arte olha para a direita).
## Os lados esquerdos são obtidos espelhando a sprite via flip_h.
const FLY_RIGHT: StringName = &"fly_rith"
const FLY_LEFT_ALIAS: StringName = &"fly_left"
const FLY_DOWN: StringName = &"fly_down"
const FLY_UP: StringName = &"fly_up"
const ATTACK_RIGHT: StringName = &"atack_right"
const ATTACK_LEFT_ALIAS: StringName = &"attack_left"
const ATTACK_DOWN: StringName = &"atack_down"

## Velocidade do voo de patrulha ao redor do jogador
@export var flight_speed: float = 170.0
## Raio horizontal da órbita em volta do jogador
@export var orbit_radius_x: float = 150.0
## Distância mínima acima do jogador
@export var flight_altitude: float = 70.0
## Variação vertical extra da órbita (sempre acima do jogador)
@export var orbit_height_range: float = 45.0
## Velocidade angular da órbita (rad/s)
@export var orbit_speed: float = 0.7
## Velocidade do mergulho de ataque
@export var attack_dive_speed: float = 260.0
## Delay para o hitbox ligar, sincronizado com o frame de impacto
@export var attack_hit_delay: float = 0.3
## Tempo que o hitbox permanece ativo
@export var attack_hit_duration: float = 0.25
## Duração total do estado de ataque
@export var attack_total_duration: float = 0.8

## Offset atual do hitbox, definido pelo estado de ataque
var hitbox_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	sprite_faces_right = true
	animated_sprite_2d.flip_h = false
	_prepare_animations()


## Reativa a colisão do corpo, que o portal desabilita durante o spawn
func _on_spawn_complete() -> void:
	super._on_spawn_complete()
	var body_shape := $CollisionShape2D as CollisionShape2D
	if body_shape:
		body_shape.disabled = false


## Garante loop no voo e ataque único nas animações de ataque
func _prepare_animations() -> void:
	var frames := animated_sprite_2d.sprite_frames
	if frames == null:
		return
	for animation in [FLY_RIGHT, FLY_LEFT_ALIAS, FLY_DOWN, FLY_UP]:
		if frames.has_animation(animation):
			frames.set_animation_loop(animation, true)
	for animation in [ATTACK_RIGHT, ATTACK_LEFT_ALIAS, ATTACK_DOWN]:
		if frames.has_animation(animation):
			frames.set_animation_loop(animation, false)


## Posição alvo na órbita, sempre acima do jogador
func get_orbit_position(angle: float) -> Vector2:
	if player == null:
		return global_position
	var orbit_offset := Vector2(
		cos(angle) * orbit_radius_x,
		-flight_altitude - orbit_height_range + sin(angle) * orbit_height_range
	)
	return player.global_position + orbit_offset


## Atualiza o lado para onde a sprite olha (a arte olha para a direita)
func set_facing(direction: Vector2) -> void:
	if animated_sprite_2d == null or absf(direction.x) < 0.01:
		return
	enemy_direction = Vector2(signf(direction.x), 0.0)
	animated_sprite_2d.flip_h = direction.x < 0.0


## Toca a animação de voo lateral (o lado esquerdo é o espelho do direito)
func play_fly_animation(_direction: Vector2) -> void:
	if animated_sprite_2d == null:
		return
	var animation := FLY_LEFT_ALIAS if animated_sprite_2d.flip_h else FLY_RIGHT
	_play_if_changed(animation, FLY_RIGHT)


## Toca a animação de ataque e devolve o offset do hitbox para essa direção
func play_attack_animation(direction_to_player: Vector2) -> Vector2:
	var animation := ATTACK_DOWN
	hitbox_offset = Vector2(0.0, 36.0)

	if absf(direction_to_player.x) > 12.0:
		animation = ATTACK_RIGHT
		set_facing(direction_to_player)
		hitbox_offset = Vector2(signf(direction_to_player.x) * 36.0, 0.0)

	if not _has_animation(animation):
		animation = ATTACK_RIGHT
	if _has_animation(animation):
		# Sempre reinicia do primeiro frame, mesmo repetindo o mesmo ataque
		animated_sprite_2d.play(animation)
	return hitbox_offset


## O hitbox do Crow é posicionado pelo estado de ataque, não pela orientação padrão
func _apply_hitbox_flip_position() -> void:
	if hit_component_collision_shape == null:
		return
	hit_component_collision_shape.position = hitbox_offset


func on_hurt(hit_damage: int) -> void:
	if is_dead:
		return
	print("👹[CROW] Recebeu ", hit_damage, " de dano. Vida: ", current_health)
	adicionar_vida(-hit_damage)


func _has_animation(animation: StringName) -> bool:
	if animated_sprite_2d == null or animated_sprite_2d.sprite_frames == null:
		return false
	return animated_sprite_2d.sprite_frames.has_animation(animation)


func _play_if_changed(animation: StringName, fallback: StringName) -> void:
	if not _has_animation(animation):
		animation = fallback
	if not _has_animation(animation):
		return
	if animated_sprite_2d.animation != animation or not animated_sprite_2d.is_playing():
		animated_sprite_2d.play(animation)
