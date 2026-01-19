extends NodeState

var player: Player
var animated_sprite_2d: AnimatedSprite2D


func _on_enter() -> void:
	# Pega as referências dos nós quando o estado é ativado
	player = owner as CharacterBody2D
	animated_sprite_2d = player.get_node("AnimatedSprite2D")
	if animated_sprite_2d:
		animated_sprite_2d.play("idle_front")


func _on_process(_delta: float) -> void:
	pass


func _on_physics_process(_delta: float) -> void:		
	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("idle_back")
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("idle_front")
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("idle_left")
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("idle_right")


func _on_next_transitions() -> void:
	# Se houver movimentação chama a transição andando	
	# Se clicar com o botão esquerdo do mouse chama a animação correspondente
	GameInputEvents.movement_input()
	if GameInputEvents.is_moviment_input():
		transition.emit("walk")
	if player.current_tool == DataTypes.Tools.AxeWood && GameInputEvents.use_tool():
		transition.emit("Chopping")
	if player.current_tool == DataTypes.Tools.TillGround && GameInputEvents.use_tool():
		transition.emit("Tilling")
	if player.current_tool == DataTypes.Tools.WaterCrops && GameInputEvents.use_tool():
		transition.emit("Watering")	


func _on_exit() -> void:
	animated_sprite_2d.stop()
