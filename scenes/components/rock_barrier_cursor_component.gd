class_name RockBarrierCursorComponent
extends Node

## Tilemap usado como referência de grade (Grass)
@export var grass_tilemap_layer: TileMapLayer

var rock_barrier_scene = preload("res://scenes/objects/rocks/rock_barrier.tscn")

var player: Player
var mouse_position: Vector2
var cell_position: Vector2i
var local_cell_position: Vector2
var distance: float

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


## Trata os inputs de colocar/remover barreira (mesmo padrão de CropCursorComponent)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("remove_dirt"):
		if ToolManager.selected_tool == DataTypes.Tools.BuildRock:
			get_cell_under_mouse()
			remove_barrier()
	elif event.is_action_pressed("hit"):
		if ToolManager.selected_tool == DataTypes.Tools.BuildRock:
			get_cell_under_mouse()
			add_barrier()


func get_cell_under_mouse() -> void:
	mouse_position = grass_tilemap_layer.get_local_mouse_position()
	cell_position = grass_tilemap_layer.local_to_map(mouse_position)
	local_cell_position = grass_tilemap_layer.map_to_local(cell_position)
	distance = player.global_position.distance_to(local_cell_position)


## Coloca uma barreira na célula sob o mouse, consumindo 1 pedra do inventário
func add_barrier() -> void:
	if distance >= 20.0:
		return
	if InventoryManager.get_inventory_count("stone") <= 0:
		return
	if _has_barrier_at(local_cell_position):
		return

	InventoryManager.remove_collectable("stone")
	var barrier: Node2D = rock_barrier_scene.instantiate()
	barrier.global_position = local_cell_position
	_get_or_create_rockbarriers().add_child(barrier)


## Remove a barreira da célula sob o mouse e devolve 1 pedra
func remove_barrier() -> void:
	if distance >= 20.0:
		return
	var container = _get_rockbarriers()
	if container == null:
		return
	for node: Node2D in container.get_children():
		if node.global_position.distance_to(local_cell_position) < 8.0:
			node.queue_free()
			InventoryManager.add_collectable("stone")
			return


func _has_barrier_at(pos: Vector2) -> bool:
	var container = _get_rockbarriers()
	if container == null:
		return false
	for node: Node2D in container.get_children():
		if node.global_position.distance_to(pos) < 8.0:
			return true
	return false


func _get_rockbarriers() -> Node2D:
	var parent = get_parent()
	if parent == null:
		return null
	return parent.find_child("RockBarriers")


func _get_or_create_rockbarriers() -> Node2D:
	var container = _get_rockbarriers()
	if container == null:
		container = Node2D.new()
		container.name = "RockBarriers"
		get_parent().add_child(container)
	return container
