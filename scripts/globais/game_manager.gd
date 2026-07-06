extends Node

var game_menu_screen = preload("res://scenes/ui/game_menu_screen.tscn")

func _ready():
	await get_tree().process_frame

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_menu"):
		# Para TODOS os áudios através do AudioManager
		AudioManager.stop_all_audio_in_scene()
		show_game_menu_screen()

func start_game() -> void:
	SceneManager.load_main_scene_container()
	SceneManager.load_level("Level1") 
	SaveGameManager.load_game()
	SaveGameManager.allow_save_game = true
	AudioManager.play_level_music()

func exit_game() -> void:
	get_tree().quit()

func show_game_menu_screen() -> void:
	var game_menu_screen_instance = game_menu_screen.instantiate()
	get_tree().root.add_child(game_menu_screen_instance)
