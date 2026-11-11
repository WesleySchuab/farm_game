extends CanvasLayer

@onready var save_game_button: Button = $MarginContainer/VBoxContainer/SaveGameButton
@onready var music_volume_slider: HSlider = $MarginContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_value: Label = $MarginContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeValue

var save_component: SaveLevelDataComponent

	

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed():
		return
	
	match event.as_text_keycode():
		"S":
			_on_star_game_button_pressed()
		"V":
			if SaveGameManager.allow_save_game:
				_on_save_game_button_pressed()
		"Escape":
			_on_exit_button_pressed()
		"R":
			_on_restart_pressed()


func _ready() -> void:
	save_component = get_tree().get_first_node_in_group("save_level_data_component")
	save_game_button.disabled = !SaveGameManager.allow_save_game
	save_game_button.focus_mode = SaveGameManager.allow_save_game if Control.FOCUS_ALL else Control.FOCUS_NONE
	var initial_volume := AudioManager.get_music_volume_linear() * 100.0
	music_volume_slider.set_value_no_signal(initial_volume)
	music_volume_value.text = "%d%%" % roundi(initial_volume)
	
	# Música do menu via AudioManager
	AudioManager.play_music(AudioManager.MUSIC.OPENING, -10.0, 0.61)

func _on_music_volume_slider_value_changed(value: float) -> void:
	music_volume_value.text = "%d%%" % roundi(value)
	AudioManager.set_music_volume_linear(value / 100.0)

func _on_star_game_button_pressed() -> void:
	GameManager.start_game()
	queue_free()

func _on_save_game_button_pressed() -> void:
	SaveGameManager.save_game()

func _on_exit_button_pressed() -> void:
	GameManager.exit_game()


func _on_restart_pressed() -> void:
	if SaveGameManager.delete_all_saves():
		print("Todos os salvamentos foram apagados!")
		GameManager.start_game()
		queue_free()
	else:
		print("Erro ao apagar salvamentos")
   
