extends NonPlayableCharacter

var chicken_sound: AudioStream = preload("res://game/assets/audio/sfx/chicken-cluck-1.ogg")

func _ready() -> void:
	walk_cycles = randi_range(min_walk_cycle, max_walk_cycle)
	
	# Adiciona o componente de som do animal
	var sound_component = AnimalSoundComponent.new()
	sound_component.animal_sound = chicken_sound
	sound_component.sound_interval = randf_range(15.0, 40.0)  # somn a cada 10.0, 20.0 segundos
	sound_component.sound_chance = 0.2  # 40% de chance
	sound_component.volume_db = -8.0
	add_child(sound_component)
	
	
