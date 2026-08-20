extends NonPlayableCharacter

func _ready() -> void:
	walk_cycles = randi_range(min_walk_cycle, max_walk_cycle)
	
	# Adiciona o componente de som do animal
	var sound_component = AnimalSoundComponent.new()
	sound_component.animal_sfx = AudioManager.SFX.COW_MOO
	sound_component.use_variation = false
	sound_component.sound_interval = randf_range(20.0, 40.0)  # Vaca muge a cada 20-40s
	sound_component.sound_chance = 0.2  # 20% de chance
	sound_component.volume_db = -5.0
	add_child(sound_component)

