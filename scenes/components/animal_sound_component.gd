class_name AnimalSoundComponent
extends Node

## Som do animal (vaca, galinha, etc)
@export var animal_sound: AudioStream

## Intervalo de tempo entre sons (em segundos)
@export var sound_interval: float = 5.0

## Volume do som (-80 a 0 dB)
@export var volume_db: float = 0.0

## Chance de tocar som a cada intervalo (0.0 a 1.0)
@export var sound_chance: float = 0.5

var time_since_last_sound: float = 0.0
var animal_position: Vector2


func _ready() -> void:
	animal_position = get_parent().global_position
	time_since_last_sound = randf_range(0, sound_interval)


func _process(delta: float) -> void:
	if not animal_sound:
		return
	
	time_since_last_sound += delta
	animal_position = get_parent().global_position
	
	if time_since_last_sound >= sound_interval:
		time_since_last_sound = 0.0
		
		# Chance de tocar o som
		if randf() <= sound_chance:
			play_animal_sound()


func play_animal_sound() -> void:
	"""Toca o som do animal através do AudioManager"""
	AudioManager.play_sfx_2d(animal_sound, animal_position, volume_db)


func _exit_tree() -> void:
	"""Limpa quando o componente é removido"""
	pass
