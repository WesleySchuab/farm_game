## Estado de regar as plantações
## Gerencia a animação e comportamento quando o jogador usa o regador
extends NodeState

## Referência ao jogador
@export var player: Player

## Referência ao componente de sprite animado
@export var animated_sprite_2d : AnimatedSprite2D

## Inicializa o estado de aguar
## Desabilita a colisão do componente de ataque e reseta sua posição
func  _ready() -> void:
	print("💧 Watering state _ready.")
	player.disable_player_hitbox()


## Processa a lógica do estado a cada frame
## Atualmente não implementado para este estado
func _on_process(_delta : float) -> void:
	pass


## Processa a física do estado a cada frame
## Atualmente não implementado para este estado
func _on_physics_process(_delta : float) -> void:
	pass

## Executado quando o estado é iniciado
## Determina a animação de regar baseado na direção que o jogador está olhando
func _on_enter() -> void:
	print("💧 Estado Watering ativado.")
	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("watering_back")
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("watering_right")
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("watering_front")
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("watering_left")
	else :
		animated_sprite_2d.play("watering_front")
	
	# Posiciona o hitbox via método centralizado do Player
	player.set_hitbox_position(
		Vector2(6, -16),   # UP
		Vector2(21, -3),   # RIGHT
		Vector2(-5, 6),    # DOWN
		Vector2(-21, 3)    # LEFT
	)
	player.enable_player_hitbox()
	print("💧 Collision habilitada.")

## Verifica condições para transição para o próximo estado
## Quando a animação terminar, retorna ao estado idle
func _on_next_transitions() -> void:
	if !animated_sprite_2d.is_playing():
		transition.emit("idle")
		
## Executado quando o estado é finalizado
## Para a animação atual
func _on_exit() -> void:
	animated_sprite_2d.stop()
	player.disable_player_hitbox()
	print("💧 Estado Watering desativado")
