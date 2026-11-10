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

## Velocidade do voo de patrulha
@export var flight_speed: float = 170.0
## Raio (px) do ponto distante usado no sobrevoo
@export var flyby_far_radius: float = 420.0
## Raio (px) do ponto próximo usado no sobrevoo
@export var flyby_near_radius: float = 110.0
## Distância para considerar que chegou ao ponto de sobrevoo
@export var flyby_arrival_distance: float = 24.0
## Tempo máximo perseguindo um ponto antes de trocar (segundos)
@export var flyby_waypoint_timeout: float = 3.5
## Distância mínima acima do jogador
@export var flight_altitude: float = 70.0
## Variação vertical extra do sobrevoo (sempre acima do jogador)
@export var orbit_height_range: float = 45.0
## Velocidade do mergulho de ataque
@export var attack_dive_speed: float = 260.0
## Delay para o hitbox ligar, sincronizado com o frame de impacto
@export var attack_hit_delay: float = 0.3
## Tempo que o hitbox permanece ativo
@export var attack_hit_duration: float = 0.25
## Duração total do estado de ataque
@export var attack_total_duration: float = 0.8
## Velocidade da fuga quando a fogueira é reacesa
@export var retreat_speed: float = 340.0
## Tempo até o corvo sumir após iniciar a fuga
@export var retreat_duration: float = 2.5

## Offset atual do hitbox, definido pelo estado de ataque
var hitbox_offset: Vector2 = Vector2.ZERO

## Quando true, o corvo foge do jogador e desaparece
var is_retreating: bool = false

var _retreat_time: float = 0.0


func _ready() -> void:
	super._ready()
	sprite_faces_right = true
	animated_sprite_2d.flip_h = false
	_prepare_animations()


func _process(delta: float) -> void:
	if not is_retreating:
		return
	_retreat_time += delta
	if _retreat_time >= retreat_duration:
		queue_free()


## Inicia a fuga: o corvo se afasta e desaparece após retreat_duration
func start_retreat() -> void:
	if is_retreating:
		return
	is_retreating = true
	disable_hit_box()


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


## Offset de um ponto de sobrevoo acima do jogador (near/far)
func get_flyby_offset(far: bool) -> Vector2:
	var radius := flyby_far_radius if far else flyby_near_radius
	var angle := randf_range(0.0, TAU)
	var altitude := -flight_altitude - randf_range(0.0, orbit_height_range)
	return Vector2(cos(angle) * radius, altitude)


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


## Toca a animação de fuga (subindo/afastando)
func play_flee_animation() -> void:
	_play_if_changed(FLY_UP, FLY_RIGHT)


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
