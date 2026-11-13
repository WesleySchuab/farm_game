extends TileMapLayer
class_name TilledSoil

## Texto de aviso quando a célula arada está sem semente e a ferramenta não é de plantio
@export var wrong_tool_warning: String = "Selecione a semente"
## Texto de aviso quando a cultura da célula ainda não foi regada
@export var watering_warning: String = "Use o regador"
## Tolerância (px) para considerar uma cultura posicionada na célula do jogador
@export var crop_cell_tolerance: float = 8.0

## Prompt exibido para a célula arada sob o jogador
enum PromptState {
	NONE,
	SEED_BAG,
	NEEDS_WATER,
	WRONG_TOOL
}

@onready var interactable_component: InteractableComponents = $InteractableComponent

var _player_in_range: bool = false
var _player: Player
var _crop_fields: Node2D
var _current_prompt: PromptState = PromptState.NONE

func _ready() -> void:
	interactable_component.interactable_activated.connect(_on_interactable_activated)
	interactable_component.interactable_deactivated.connect(_on_interactable_deactivated)
	# Atualiza o prompt quando o jogador troca de ferramenta
	ToolManager.tool_selected.connect(_on_tool_selected)

## Reavalia o prompt: plantar ou regar muda sem troca de ferramenta
func _process(_delta: float) -> void:
	if _player_in_range:
		_update_prompt()

func _on_interactable_activated() -> void:
	_player_in_range = true
	_update_prompt()

func _on_interactable_deactivated() -> void:
	_player_in_range = false
	_apply_prompt(PromptState.NONE)

func _on_tool_selected(_tool: DataTypes.Tools) -> void:
	_update_prompt()

func _update_prompt() -> void:
	_apply_prompt(_get_prompt_state())

## Define o aviso da célula sob o jogador: semear, regar ou nenhum
func _get_prompt_state() -> PromptState:
	var player := _get_player()
	if player == null:
		return PromptState.NONE

	var cell := local_to_map(to_local(player.global_position))
	if get_cell_source_id(cell) == -1:
		return PromptState.NONE

	var crop := _get_crop_at_cell(cell)
	if crop != null:
		var growth := crop.get_node_or_null("GrowthCycleComponent") as GrowthCycleComponent
		if growth == null or growth.is_watered:
			return PromptState.NONE
		# Com o regador equipado o aviso de regar já não é necessário
		if ToolManager.selected_tool == DataTypes.Tools.WaterCrops:
			return PromptState.NONE
		return PromptState.NEEDS_WATER

	match ToolManager.selected_tool:
		DataTypes.Tools.PlantCorn, DataTypes.Tools.PlantTomato:
			return PromptState.SEED_BAG
		_:
			return PromptState.WRONG_TOOL

func _apply_prompt(state: PromptState) -> void:
	if state == _current_prompt:
		return
	_current_prompt = state

	match state:
		PromptState.SEED_BAG:
			EventBus.show_seed_bag.emit()
		PromptState.NEEDS_WATER:
			EventBus.show_action_warning.emit(watering_warning)
		PromptState.WRONG_TOOL:
			EventBus.show_action_warning.emit(wrong_tool_warning)
		_:
			EventBus.hide_action_prompt.emit()

func _get_player() -> Player:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	return _player

## Cultura posicionada no centro da célula informada
func _get_crop_at_cell(cell: Vector2i) -> Node2D:
	var crop_fields := _get_crop_fields()
	if crop_fields == null:
		return null
	var cell_global := to_global(map_to_local(cell))
	for child in crop_fields.get_children():
		if child is Node2D and child.global_position.distance_to(cell_global) <= crop_cell_tolerance:
			return child
	return null

func _get_crop_fields() -> Node2D:
	if _crop_fields == null or not is_instance_valid(_crop_fields):
		# TilledSoil fica dentro de GameTileMap; CropFields é irmão dele no nível
		var level_root: Node = owner if owner != null else get_tree().current_scene
		if level_root == null:
			level_root = get_parent()
		_crop_fields = level_root.find_child("CropFields") as Node2D
	return _crop_fields
