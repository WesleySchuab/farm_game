class_name AnimalSoundComponent
extends Node

## Som do animal (ID do enum AudioManager.SFX)
@export var animal_sfx: int = -1

## Usa variação de samples (ex: clucks 1/2/3 da galinha)
@export var use_variation: bool = true

## Intervalo de tempo entre sons (em segundos)
@export var sound_interval: float = 5.0

## Volume do som (-80 a 0 dB)
@export var volume_db: float = 0.0

## Chance de tocar som a cada intervalo (0.0 a 1.0)
@export var sound_chance: float = 0.5

var time_since_last_sound: float = 0.0


func _ready() -> void:
	time_since_last_sound = randf_range(0.0, sound_interval)


func _process(delta: float) -> void:
	if animal_sfx < 0:
		return
	
	time_since_last_sound += delta
	
	if time_since_last_sound >= sound_interval:
		time_since_last_sound = 0.0
		
		# Chance de tocar o som
		if randf() <= sound_chance:
			_play_animal_sound()


func _play_animal_sound() -> void:
	"""Toca o som do animal através do AudioManager"""
	var pos := _owner_pos()
	if use_variation:
		AudioManager.play_sfx_varied_at(animal_sfx, pos, 0.1, volume_db)
	else:
		AudioManager.play_sfx_at(animal_sfx, pos, volume_db)


func _owner_pos() -> Vector2:
	var parent = get_parent()
	if parent is Node2D:
		return parent.global_position
	return Vector2.ZERO

