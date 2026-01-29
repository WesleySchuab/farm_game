extends NodeState
@export var chacarter: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	pass


func _on_next_transitions() -> void:
	pass


func _on_enter() -> void:
	animated_sprite_2d.play("walk")


func _on_exit() -> void:
	animated_sprite_2d.stop()
