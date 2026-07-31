extends NodeState
@export var player: Player
@export var animated_sprite_2d : AnimatedSprite2D

## Inicializa o estado de corte
## Desabilita a colisão do componente de ataque e reseta sua posição
func  _ready() -> void:
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
## Determina a animação de corte e posição da área de ataque baseado na direção do jogador
## Habilita o componente de colisão para detectar acertos
func _on_enter() -> void:
	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("chopping_back")
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("chopping_right")
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("chopping_front")
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("chopping_left")
	else :
		animated_sprite_2d.play("chopping_front")
	
	# Posiciona o hitbox via método centralizado do Player
	player.set_hitbox_position(
		Vector2(6, -16),   # UP
		Vector2(10, 0),    # RIGHT
		Vector2(-5, 6),    # DOWN
		Vector2(-10, 0)    # LEFT
	)
	player.enable_player_hitbox()

## Verifica condições para transição para o próximo estado
## Quando a animação terminar, retorna ao estado idle
func _on_next_transitions() -> void:
	if !animated_sprite_2d.is_playing():
		transition.emit("idle")
	player.disable_player_hitbox()
		
## Executado quando o estado é finalizado
## Para a animação atual
func _on_exit() -> void:
	animated_sprite_2d.stop()
	player.disable_player_hitbox()
