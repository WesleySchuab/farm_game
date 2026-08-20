extends NonPlayableCharacter

func _ready() -> void:
	walk_cycles = randi_range(min_walk_cycle, max_walk_cycle)
	
	# Adiciona o componente de som do animal
	var sound_component = AnimalSoundComponent.new()
	sound_component.animal_sfx = AudioManager.SFX.CHICKEN_CLUCK_1
	sound_component.use_variation = true
	sound_component.sound_interval = randf_range(15.0, 40.0)  # som a cada 15-40 segundos
	sound_component.sound_chance = 0.2  # 20% de chance
	sound_component.volume_db = -8.0
	add_child(sound_component)
