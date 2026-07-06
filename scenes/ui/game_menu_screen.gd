extends CanvasLayer

@onready var save_game_button: Button = $MarginContainer/VBoxContainer/SaveGameButton

var save_component: SaveLevelDataComponent
@onready var openig_audio_stream_player: AudioStreamPlayer = $OpenigAudioStreamPlayer

	

func _ready() -> void:
	save_component = get_tree().get_first_node_in_group("save_level_data_component")
	save_game_button.disabled = !SaveGameManager.allow_save_game
	save_game_button.focus_mode = SaveGameManager.allow_save_game if Control.FOCUS_ALL else Control.FOCUS_NONE
	
	# Se você quiser que a música comece tocando:
	openig_audio_stream_player.play()

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
   
