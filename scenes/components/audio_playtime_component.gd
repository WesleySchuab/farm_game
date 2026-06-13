extends Timer
@export var audio_playtime_player2D: AudioStreamPlayer2D


func _on_timeout() -> void:
	audio_playtime_player2D.play()
