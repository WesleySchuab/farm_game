extends Node2D

func _ready():
	# Inicia a música do nível através do AudioManager
	AudioManager.play_level_music()


func _exit_tree() -> void:
	"""Para a música quando o nível é descarregado"""
	AudioManager.stop_level_music()
