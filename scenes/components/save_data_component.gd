class_name SaveDataComponent
extends Node

@export var parent_node: Node2D
@export var save_data_resource : NodeDataReource

func _ready() -> void:
	add_to_group("save_data_component")
	if parent_node == null:
		parent_node = get_parent() as Node2D

func _save_data()-> NodeDataReource:
	if parent_node == null:
		parent_node = get_parent() as Node2D

	if parent_node == null:
		push_warning("SaveDataComponent sem parent_node válido: " + str(name))
		return null

	var has_scene_path := !String(parent_node.scene_file_path).is_empty()
	if save_data_resource == null:
		if has_scene_path:
			push_warning("SaveDataComponent sem save_data_resource, usando SceneDataResource padrão: " + str(parent_node.name))
			save_data_resource = SceneDataResource.new()
		else:
			push_warning("SaveDataComponent sem save_data_resource, usando NodeDataReource padrão: " + str(parent_node.name))
			save_data_resource = NodeDataReource.new()
	elif has_scene_path and !(save_data_resource is SceneDataResource):
		push_warning("SaveDataComponent com recurso incompatível para cena instanciada, trocando para SceneDataResource: " + str(parent_node.name))
		save_data_resource = SceneDataResource.new()
	save_data_resource._save_data(parent_node)
	return save_data_resource
	
