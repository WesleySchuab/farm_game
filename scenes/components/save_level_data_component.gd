class_name SaveLevelDataComponent
extends Node

const SaveGameDataResource = preload("res://resources/save_game_data_resource.gd")
const SaveDataComponent = preload("res://scenes/components/save_data_component.gd")
const NodeDataResource = preload("res://resources/node_data_resource.gd")

var level_scene_name: String
var save_game_data_path: String = "user://game_data/"
var save_file_name: String = "save_%s_game_data.tres"
var game_data_resource: SaveGameDataResource


func _ready() -> void:
	add_to_group("save_level_data_component")
	level_scene_name = get_parent().name


func save_node_data() -> void:
	var nodes = get_tree().get_nodes_in_group("save_data_component")
	
	game_data_resource = SaveGameDataResource.new()
	
	if nodes != null:
		for node: SaveDataComponent in nodes:
			if node is SaveDataComponent:
				var save_data_resource: NodeDataResource = node._save_data()
				var save_final_resource = save_data_resource.duplicate()
				game_data_resource.save_data_nodes.append(save_final_resource)


func save_game() -> void:
	var absolute_save_path: String = ProjectSettings.globalize_path(save_game_data_path)
	if !DirAccess.dir_exists_absolute(absolute_save_path):
		var error = DirAccess.make_dir_recursive_absolute(absolute_save_path)
		if error != OK:
			push_error("SaveLevelDataComponent: erro ao criar diretório %s (erro %d)" % [absolute_save_path, error])
			return

	var level_save_file_name: String = save_file_name % level_scene_name

	save_node_data()

	var full_save_path: String = save_game_data_path + level_save_file_name
	var result: int = ResourceSaver.save(game_data_resource, full_save_path)
	print("save result:", result, "path:", full_save_path)
	if result != OK:
		push_error("Failed to save game data to %s (error %d)" % [full_save_path, result])


func load_game() -> void:
	var level_save_file_name: String = save_file_name % level_scene_name
	var save_game_path: String = save_game_data_path + level_save_file_name
	
	if !FileAccess.file_exists(save_game_path):
		return
	
	game_data_resource = ResourceLoader.load(save_game_path)
	
	if game_data_resource == null:
		return
	
	var root_node: Window = get_tree().root
	
	for resource in game_data_resource.save_data_nodes:
		if resource is Resource:
			if resource is NodeDataResource:
				resource._load_data(root_node)


func delete_save() -> bool:
	"""Deleta o salvamento do nível atual"""
	var level_save_file_name: String = save_file_name % level_scene_name
	var full_save_path: String = save_game_data_path + level_save_file_name
	
	if !FileAccess.file_exists(full_save_path):
		print("SaveLevelDataComponent: Arquivo de salvamento não encontrado: %s" % full_save_path)
		return false
	
	var absolute_path: String = ProjectSettings.globalize_path(full_save_path)
	var error = DirAccess.remove_absolute(absolute_path)
	
	if error != OK:
		push_error("SaveLevelDataComponent: Erro ao deletar %s (erro %d)" % [full_save_path, error])
		return false
	
	print("SaveLevelDataComponent: Salvamento de %s foi deletado com sucesso" % level_scene_name)
	game_data_resource = null
	return true


func has_save() -> bool:
	"""Verifica se existe um salvamento para o nível atual"""
	var level_save_file_name: String = save_file_name % level_scene_name
	var full_save_path: String = save_game_data_path + level_save_file_name
	
	return FileAccess.file_exists(full_save_path)
