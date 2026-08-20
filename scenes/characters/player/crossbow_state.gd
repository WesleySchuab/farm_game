## Estado de disparo da besta (Crossbow)
## Gerencia a mira, o disparo de flechas e a animação do jogador
extends NodeState

## Referência ao jogador
@export var player: Player

## Referência ao componente de sprite animado
@export var animated_sprite_2d: AnimatedSprite2D

## Componente de SFX para tocar som de disparo
@export var sfx_component: SFXComponent

## Cena da flecha instanciada ao disparar
const ARROW_SCENE: PackedScene = preload("res://scenes/objects/weapons/arrow.tscn")

## Velocidade da flecha disparada
@export var arrow_speed: float = 250.0

## Dano causado pela flecha
@export var arrow_damage: int = 10

## Tempo máximo de segurança para evitar travar no estado (fallback)
@export var shoot_timeout: float = 3.0

var time_in_state: float = 0.0
var animation_finished: bool = false


## Executado quando o estado é iniciado
## Toca a animação de tiro e dispara a flecha
func _on_enter() -> void:
	time_in_state = 0.0
	animation_finished = false
	
	# Conecta ao sinal de fim da animação para transitar de volta ao idle
	if not animated_sprite_2d.animation_finished.is_connected(_on_shoot_animation_finished):
		animated_sprite_2d.animation_finished.connect(_on_shoot_animation_finished)
	
	_play_shoot_animation()
	_shoot_arrow()
	
	# Toca o som de disparo da besta
	if sfx_component:
		sfx_component.attack_triggered.emit()


## Processa a lógica do estado a cada frame
func _on_process(delta: float) -> void:
	time_in_state += delta


## Processa a física do estado a cada frame
func _on_physics_process(_delta: float) -> void:
	pass


## Verifica condições para transição para o próximo estado
## Retorna ao idle quando a animação de tiro terminar ou após timeout de segurança
func _on_next_transitions() -> void:
	if animation_finished or time_in_state >= shoot_timeout:
		transition.emit("idle")


## Executado quando o estado é finalizado
func _on_exit() -> void:
	if animated_sprite_2d.animation_finished.is_connected(_on_shoot_animation_finished):
		animated_sprite_2d.animation_finished.disconnect(_on_shoot_animation_finished)
	animated_sprite_2d.stop()


## Callback quando a animação de tiro termina
func _on_shoot_animation_finished() -> void:
	animation_finished = true


## Toca a animação de tiro baseada na direção que o jogador está olhando
func _play_shoot_animation() -> void:
	var anim_name: String = "shoot_crossbow_front"
	if player.player_direction == Vector2.UP:
		anim_name = "shoot_crossbow_back"
	elif player.player_direction == Vector2.RIGHT:
		anim_name = "shoot_crossbow_right"
	elif player.player_direction == Vector2.DOWN:
		anim_name = "shoot_crossbow_front"
	elif player.player_direction == Vector2.LEFT:
		anim_name = "shoot_crossbow_left"
	animated_sprite_2d.play(anim_name)


## Instancia a flecha, posiciona e orienta na direção do jogador
func _shoot_arrow() -> void:
	var direction: Vector2 = player.player_direction
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN

	var arrow: Arrow = ARROW_SCENE.instantiate()
	arrow.speed = arrow_speed
	arrow.hit_damage = arrow_damage
	arrow.rotation = direction.angle()

	# Adiciona a flecha à cena raiz (usando get_tree().root que é sempre disponível)
	get_tree().root.add_child(arrow)
	arrow.global_position = player.global_position + direction * 12
	
	print("🏹 [CROSSBOW] Flecha disparada! Posição: ", arrow.global_position, " | Rotação: ", arrow.rotation)
