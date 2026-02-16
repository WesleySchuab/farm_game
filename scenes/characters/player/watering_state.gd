## Estado de regar as plantações
## Gerencia a animação e comportamento quando o jogador usa o regador
extends NodeState

## Referência ao jogador
@export var player: Player

## Referência ao componente de sprite animado
@export var animated_sprite_2d : AnimatedSprite2D
@export var hit_component_collision_shape : CollisionShape2D

## Inicializa o estado de aguar
## Desabilita a colisão do componente de ataque e reseta sua posição
func  _ready() -> void:
	print("💧 Watering state _ready. CollisionShape: ", hit_component_collision_shape)
	if hit_component_collision_shape:
		hit_component_collision_shape.disabled = true
		hit_component_collision_shape.position = Vector2(0,0)
	else:
		print("❌ ERRO: hit_component_collision_shape é null!") 


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
	print("💧 Estado Watering ativado. Collision disabled: ", hit_component_collision_shape.disabled)
	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("watering_back")
		hit_component_collision_shape.position = Vector2(6,-16)
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("watering_right")
		hit_component_collision_shape.position = Vector2(21,-3)
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("watering_front")
		hit_component_collision_shape.position = Vector2(-5,6)
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("watering_left")
		hit_component_collision_shape.position = Vector2(-21,3)
	else :
		animated_sprite_2d.play("watering_front")
		hit_component_collision_shape.position = Vector2(-5,6)
	hit_component_collision_shape.disabled = false
	print("💧 Collision habilitada. Disabled: ", hit_component_collision_shape.disabled)

## Verifica condições para transição para o próximo estado
## Quando a animação terminar, retorna ao estado idle
func _on_next_transitions() -> void:
	if !animated_sprite_2d.is_playing():
		transition.emit("idle")
		
## Executado quando o estado é finalizado
## Para a animação atual
func _on_exit() -> void:
	animated_sprite_2d.stop()
	hit_component_collision_shape.disabled = true
	print("💧 Estado Watering desativado")
