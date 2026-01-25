## Estado de caminhada do jogador
## Gerencia movimento, animações e transições enquanto o jogador está andando
extends NodeState

## Referência ao jogador
@export var player : Player

## Referência ao componente de sprite animado
@export var animated_sprite_2d : AnimatedSprite2D

## Velocidade de movimento do jogador em pixels por segundo
@export var speed : int = 50
 
## Processa a lógica do estado a cada frame
## Atualmente não implementado para este estado
func _on_process(_delta : float) -> void:
	pass

## Processa a física do movimento a cada frame
## Obtém a direção do input, atualiza a animação correspondente
## Atualiza a direção do jogador e move o personagem
func _on_physics_process(_delta : float) -> void:
	
	var direction: Vector2 = GameInputEvents.movement_input()
	
	print("direção = ", direction)
	
	if direction == Vector2.UP:
		animated_sprite_2d.play("walk_back")
	elif direction == Vector2.DOWN:
		animated_sprite_2d.play("walk_front")
	elif direction == Vector2.LEFT:
		animated_sprite_2d.play("walk_left")
	elif direction == Vector2.RIGHT:
		animated_sprite_2d.play("walk_right")
	if direction != Vector2.ZERO:
		player.player_direction = direction
	player.velocity = direction * speed
	player.move_and_slide()

## Verifica condições para transição para outros estados
## Retorna ao idle quando não há input de movimento
## Transita para Chopping se a ferramenta machado estiver equipada e o jogador usar a ferramenta
func _on_next_transitions() -> void:
	#var movement = GameInputEvents.movement_input()
	#if movement == Vector2.ZERO:
	if !GameInputEvents.movement_input():
		transition.emit("idle")
	if player.current_tool == DataTypes.Tools.AxeWood && GameInputEvents.use_tool():
		transition.emit("Chopping")


## Executado quando o estado de caminhada é iniciado
## Atualmente não há lógica de inicialização específica
func _on_enter() -> void:
	pass



## Executado quando o estado de caminhada é finalizado
## Para a animação atual
func _on_exit() -> void:
	animated_sprite_2d.stop()
