extends Node

var allow_save_game: bool

func _ready() -> void:
	await get_tree().process_frame

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		save_game()


func save_game() -> void:
	var save_level_data_component: SaveLevelDataComponent = get_tree().get_first_node_in_group("save_level_data_component")
	
	if save_level_data_component != null:
		save_level_data_component.save_game()
		print ("Jogo salvo")
	else:
		print("SaveGameManager: nenhum SaveLevelDataComponent encontrado no nó atual.")


func load_game() -> void:
	await get_tree().process_frame
	
	var save_level_data_component: SaveLevelDataComponent = get_tree().get_first_node_in_group("save_level_data_component")
	
	if save_level_data_component != null:
		save_level_data_component.load_game()


func delete_all_saves() -> bool:
	"""Deleta todos os arquivos de salvamento do jogo"""
	var save_game_data_path: String = "user://game_data/"
	var absolute_save_path: String = ProjectSettings.globalize_path(save_game_data_path)
	
	if !DirAccess.dir_exists_absolute(absolute_save_path):
		print("SaveGameManager: Diretório de salvamento não existe")
		return true
	
	var dir: DirAccess = DirAccess.open(absolute_save_path)
	if dir == null:
		push_error("SaveGameManager: Erro ao abrir diretório %s (erro %s)" % [absolute_save_path, error_string(DirAccess.get_open_error())])
		return false
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres") and file_name.begins_with("save_"):
			var file_path: String = absolute_save_path + file_name
			var error = DirAccess.remove_absolute(file_path)
			if error != OK:
				push_error("SaveGameManager: Erro ao deletar %s (erro %d)" % [file_path, error])
				return false
			print("SaveGameManager: Arquivo %s deletado com sucesso" % file_name)
		
		file_name = dir.get_next()
	
	print("SaveGameManager: Todos os salvamentos foram deletados")
	return true


func delete_level_save(level_name: String) -> bool:
	"""Deleta o salvamento de um nível específico"""
	var save_game_data_path: String = "user://game_data/"
	var save_file_name: String = "save_%s_game_data.tres"
	var level_save_file_name: String = save_file_name % level_name
	var full_save_path: String = save_game_data_path + level_save_file_name
	
	if !FileAccess.file_exists(full_save_path):
		print("SaveGameManager: Arquivo de salvamento não encontrado: %s" % full_save_path)
		return false
	
	var error = DirAccess.remove_absolute(ProjectSettings.globalize_path(full_save_path))
	if error != OK:
		push_error("SaveGameManager: Erro ao deletar %s (erro %d)" % [full_save_path, error])
		return false
	
	print("SaveGameManager: Salvamento de %s foi deletado com sucesso" % level_name)
	return true


func has_save_file(level_name: String) -> bool:
	"""Verifica se existe um salvamento para um nível específico"""
	var save_game_data_path: String = "user://game_data/"
	var save_file_name: String = "save_%s_game_data.tres"
	var level_save_file_name: String = save_file_name % level_name
	var full_save_path: String = save_game_data_path + level_save_file_name
	
	return FileAccess.file_exists(full_save_path)
