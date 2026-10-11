class_name CropCursorComponent
extends Node

@export var tilled_soil_tilemap_layer : TileMapLayer
@onready var player: Player = get_tree().get_first_node_in_group("player")

var corn_plant_scene = preload("res://scenes/objects/plants/corn.tscn")
var tomato_plant_scene = preload("res://scenes/objects/plants/tomato.tscn")

var mouse_position: Vector2
var cell_position: Vector2i
var cell_source_id: int
var local_cell_position: Vector2
var distance: float

## Última célula onde o plantio automático foi feito (evita plantar de novo na mesma célula)
var _last_auto_plant_cell: Vector2i = Vector2i(999999, 999999)

func _process(_delta: float) -> void:
	_auto_plant_if_on_tilled_soil()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("remove_dirt"):
		if ToolManager.selected_tool == DataTypes.Tools.TillGround:
			get_cell_under_mouse()
			remove_crop()
			

			

func get_cell_under_mouse() -> void:
	mouse_position = tilled_soil_tilemap_layer.get_local_mouse_position()
	cell_position = tilled_soil_tilemap_layer.local_to_map(mouse_position)
	cell_source_id = tilled_soil_tilemap_layer.get_cell_source_id(cell_position)
	local_cell_position = tilled_soil_tilemap_layer.map_to_local(cell_position)
	distance = player.global_position.distance_to(local_cell_position)

func _auto_plant_if_on_tilled_soil() -> void:
	var tool: DataTypes.Tools = ToolManager.selected_tool
	if tool != DataTypes.Tools.PlantCorn and tool != DataTypes.Tools.PlantTomato:
		_last_auto_plant_cell = Vector2i(999999, 999999)
		return

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
	if player == null or tilled_soil_tilemap_layer == null:
		return

	var cell := tilled_soil_tilemap_layer.local_to_map(tilled_soil_tilemap_layer.to_local(player.global_position))
	if cell == _last_auto_plant_cell:
		return
	_last_auto_plant_cell = cell

	# Só planta em célula arada (com tile) e sem cultura
	if tilled_soil_tilemap_layer.get_cell_source_id(cell) == -1:
		return
	if _has_crop_at_cell(cell):
		return

	_plant_crop_at_cell(cell, tool)


func _plant_crop_at_cell(cell: Vector2i, tool: DataTypes.Tools) -> void:
	var plant_global_pos := tilled_soil_tilemap_layer.to_global(tilled_soil_tilemap_layer.map_to_local(cell))
	var crop_fields := _get_or_create_cropfields()

	if tool == DataTypes.Tools.PlantCorn:
		var corn_instance := corn_plant_scene.instantiate() as Node2D
		corn_instance.global_position = plant_global_pos
		var corn_growth := corn_instance.get_node("GrowthCycleComponent") as GrowthCycleComponent
		corn_growth.is_watered = false
		crop_fields.add_child(corn_instance)
	elif tool == DataTypes.Tools.PlantTomato:
		var tomato_instance := tomato_plant_scene.instantiate() as Node2D
		tomato_instance.global_position = plant_global_pos
		var tomato_growth := tomato_instance.get_node("GrowthCycleComponent") as GrowthCycleComponent
		tomato_growth.is_watered = false
		crop_fields.add_child(tomato_instance)


func _has_crop_at_cell(cell: Vector2i) -> bool:
	var crop_fields := get_parent().find_child("CropFields")
	if crop_fields == null:
		return false
	var plant_global_pos := tilled_soil_tilemap_layer.to_global(tilled_soil_tilemap_layer.map_to_local(cell))
	for child in crop_fields.get_children():
		if child is Node2D and child.global_position.distance_to(plant_global_pos) < 8.0:
			return true
	return false
			
func remove_crop()-> void :
	if distance < 20.0:
		var crop_nodes = get_parent().find_child("CropFields").get_children()
		
		for node: Node2D in crop_nodes:
			if node.global_position == local_cell_position:
				node.queue_free()
				
func _get_or_create_cropfields() -> Node2D:
	var parent = get_parent()
	var cf = parent.find_child("CropFields")
	if cf == null:
		cf = Node2D.new()
		cf.name = "CropFields"
		parent.add_child(cf)
	return cf
