extends Node2D

func _ready() -> void:
	# Inicia a música do nível através do AudioManager
	AudioManager.play_music(AudioManager.MUSIC.ON_THE_FARM)
	pass


func _exit_tree() -> void:
	"""Para a música quando o nível é descarregado"""
	AudioManager.stop_music()
