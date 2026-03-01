class_name SaveLevelDataComponent
extends Node

var level_scene_name: String 
var save_game_data_path: String = "user://game_data/"
var save_file_name: String = "save_%s_game_data.tres"
var game_data_resource : SaveGameDataResources

func _ready() -> void:
	add_to_group("save_level_data_component")
	level_scene_name = get_parent().name

func save_node_data()-> void:
	var nodes = get_tree().get_nodes_in_group("save_data_component")
	var saved_count := 0
	
	game_data_resource = SaveGameDataResources.new()
	
	if nodes != null:
		for node in nodes:
			if node is SaveDataComponent:
				var save_data_resource: NodeDataReource = node._save_data()
				if save_data_resource == null:
					push_warning("SaveDataComponent sem recurso válido: " + str(node.name))
					continue
				var save_final_resource = save_data_resource.duplicate()
				game_data_resource.save_data_node.append(save_final_resource)
				saved_count += 1

	print("SaveNodeData - nós salvos: ", saved_count)

func save_game()-> void:
	if !DirAccess.dir_exists_absolute(save_game_data_path):
		DirAccess.make_dir_absolute(save_game_data_path)
	
	var level_save_file_name: String = save_file_name % level_scene_name
	save_node_data()
	
	var result: int = ResourceSaver.save(game_data_resource, save_game_data_path + level_save_file_name)
	print("Save result ", result)

func load_game()-> void:
	var level_save_file_name = save_file_name % level_scene_name
	var save_game_path: String = save_game_data_path + level_save_file_name
	
	if !FileAccess.file_exists(save_game_path):
		return
	game_data_resource = ResourceLoader.load(save_game_path)
	
	if game_data_resource == null:
		return
	var root_node: Window = get_tree().root
	
	for resource in game_data_resource.save_data_node:
		if resource is Resource:
			if resource is NodeDataReource:
				resource._load_data(root_node)
	
