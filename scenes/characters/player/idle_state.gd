extends NodeState

var player: CharacterBody2D
var animated_sprite_2d: AnimatedSprite2D
var direction: Vector2


func _on_enter() -> void:
	# Pega as referências dos nós quando o estado é ativado
	player = owner as CharacterBody2D
	animated_sprite_2d = player.get_node("AnimatedSprite2D")
	if animated_sprite_2d:
		animated_sprite_2d.play("idle_front")


func _on_process(_delta: float) -> void:
	pass


func _on_physics_process(_delta: float) -> void:
	#direction = GameInputEvents.movement_input()
		
	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("idle_back")
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("idle_front")
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("idle_left")
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("idle_right")


func _on_next_transitions() -> void:
	var movement = GameInputEvents.movement_input()
	if movement != Vector2.ZERO:
		transition.emit("walk")


func _on_exit() -> void:
	animated_sprite_2d.stop()
