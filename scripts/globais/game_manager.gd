extends Node

var game_menu_screen = preload("res://scenes/ui/game_menu_screen.tscn")

func _ready():
	await get_tree().process_frame

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_echo():
		return

	# 🖥️ F11 ou Alt+Enter: alterna tela cheia em qualquer tela do jogo
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("mute"):
		AudioManager.toggle_mute()
		get_viewport().set_input_as_handled()
		return


## Alterna entre tela cheia e janela
func _toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var is_fullscreen: bool = (
		current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	print("🖥️[GAME] Tela cheia: ", not is_fullscreen)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_menu"):
		# Para TODOS os áudios através do AudioManager
		AudioManager.stop_all_audio_in_scene()
		show_game_menu_screen()

func start_game() -> void:
	SceneManager.start_game()
	SaveGameManager.load_game()
	SaveGameManager.allow_save_game = true

func exit_game() -> void:
	get_tree().quit()

func show_game_menu_screen() -> void:
	var game_menu_screen_instance = game_menu_screen.instantiate()
	get_tree().root.add_child(game_menu_screen_instance)
