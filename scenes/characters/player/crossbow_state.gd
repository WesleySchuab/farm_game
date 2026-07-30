## Estado de disparo da besta (Crossbow)
## Gerencia a mira, o disparo de flechas e a animação do jogador
extends NodeState

## Referência ao jogador
@export var player: Player

## Referência ao componente de sprite animado
@export var animated_sprite_2d: AnimatedSprite2D

## Cena da flecha instanciada ao disparar
const ARROW_SCENE: PackedScene = preload("res://scenes/objects/weapons/arrow.tscn")

## Velocidade da flecha disparada
@export var arrow_speed: float = 300.0

## Dano causado pela flecha
@export var arrow_damage: int = 10

## Tempo mínimo entre disparos (segundos), usado para segurar a animação de tiro
@export var shoot_duration: float = 0.3

var time_in_state: float = 0.0


## Executado quando o estado é iniciado
## Toca a animação de mira baseada na direção e dispara a flecha imediatamente
func _on_enter() -> void:
	time_in_state = 0.0
	_play_aim_animation()
	_shoot_arrow()


## Processa a lógica do estado a cada frame
func _on_process(delta: float) -> void:
	time_in_state += delta


## Processa a física do estado a cada frame
## Atualmente não implementado para este estado
func _on_physics_process(_delta: float) -> void:
	pass


## Verifica condições para transição para o próximo estado
## Retorna ao idle assim que a animação/duração do disparo terminar
func _on_next_transitions() -> void:
	if time_in_state >= shoot_duration:
		transition.emit("idle")


## Executado quando o estado é finalizado
func _on_exit() -> void:
	animated_sprite_2d.stop()


## Toca a animação de mira/disparo baseada na direção que o jogador está olhando
func _play_aim_animation() -> void:
	var anim_name: String = "crossbow_idle_front"
	if player.player_direction == Vector2.UP:
		anim_name = "crossbow_idle_back"
	elif player.player_direction == Vector2.RIGHT:
		anim_name = "crossbow_idle_right"
	elif player.player_direction == Vector2.DOWN:
		anim_name = "crossbow_idle_front"
	elif player.player_direction == Vector2.LEFT:
		anim_name = "crossbow_idle_left"
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
