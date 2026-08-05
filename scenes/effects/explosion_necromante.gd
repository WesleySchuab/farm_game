extends Node2D

func _ready() -> void:
	# Dispara as partículas (one_shot)
	$GPUParticles2D.emitting = true
	
	# Aguarda as partículas terminarem e se auto-remove
	await get_tree().create_timer($GPUParticles2D.lifetime).timeout
	queue_free()
