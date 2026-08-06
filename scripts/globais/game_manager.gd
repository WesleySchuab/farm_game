extends Node

var game_menu_screen = preload("res://scenes/ui/game_menu_screen.tscn")

func _ready():
	await get_tree().process_frame

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_menu"):
		# Para TODOS os áudios através do AudioManager
		AudioManager.stop_all_audio_in_scene()
		show_game_menu_screen()
	
	# Tecla M: alterna (muta/desmuta) a música
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		var bus_idx = AudioServer.get_bus_index("Music")
		var is_muted = AudioServer.is_bus_mute(bus_idx)
		AudioServer.set_bus_mute(bus_idx, not is_muted)
		print("🎵 Música %s" % ["DESMUTADA" if is_muted else "MUTADA"])

func start_game() -> void:
	SceneManager.start_game()
	SaveGameManager.load_game()
	SaveGameManager.allow_save_game = true

func exit_game() -> void:
	get_tree().quit()

func show_game_menu_screen() -> void:
	var game_menu_screen_instance = game_menu_screen.instantiate()
	get_tree().root.add_child(game_menu_screen_instance)
