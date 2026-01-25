extends NodeState
@export var player: Player
@export var animated_sprite_2d : AnimatedSprite2D
@export var hit_component_collision_shape : CollisionShape2D

## Inicializa o estado de corte
## Desabilita a colisão do componente de ataque e reseta sua posição
func  _ready() -> void:
	hit_component_collision_shape.disabled = true
	hit_component_collision_shape.position = Vector2(0,0) 

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
		hit_component_collision_shape.position = Vector2(31,7.0)
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("chopping_right")
		hit_component_collision_shape.position = Vector2(36,26)
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("chopping_front")
		hit_component_collision_shape.position = Vector2(23,29)
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("chopping_left")
		hit_component_collision_shape.position = Vector2(19,28)
	else :
		animated_sprite_2d.play("chopping_front")
		
	hit_component_collision_shape.disabled = false

## Verifica condições para transição para o próximo estado
## Quando a animação terminar, retorna ao estado idle
## Desabilita a colisão do componente de ataque
func _on_next_transitions() -> void:
	if !animated_sprite_2d.is_playing():
		transition.emit("idle")
	hit_component_collision_shape.disabled = true 
		
## Executado quando o estado é finalizado
## Para a animação atual
func _on_exit() -> void:
	animated_sprite_2d.stop()
