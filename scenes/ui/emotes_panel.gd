extends Panel

@onready var animated_sprite_2d: AnimatedSprite2D = $Emote/AnimatedSprite2D
@onready var action_prompt: Panel = $"."


func _ready() -> void:
	#action_prompt.visible = false
	animated_sprite_2d.play("right_click")
	
	
	
