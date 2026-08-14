extends TileMapLayer
class_name TilledSoil

## Texto de aviso quando a ferramenta errada está selecionada
@export var wrong_tool_warning: String = "Selecione a semente"

@onready var interactable_component: InteractableComponents = $InteractableComponent

var _player_in_range: bool = false

func _ready() -> void:
	interactable_component.interactable_activated.connect(_on_interactable_activated)
	interactable_component.interactable_deactivated.connect(_on_interactable_deactivated)
	# Atualiza o prompt quando o jogador troca de ferramenta
	ToolManager.tool_selected.connect(_on_tool_selected)

func _on_interactable_activated() -> void:
	_player_in_range = true
	_update_prompt()

func _on_interactable_deactivated() -> void:
	_player_in_range = false
	EventBus.hide_action_prompt.emit()

func _on_tool_selected(_tool: DataTypes.Tools) -> void:
	_update_prompt()

func _update_prompt() -> void:
	if not _player_in_range:
		EventBus.hide_action_prompt.emit()
		return

	# Ferramenta certa -> animação de clique; errada -> texto de aviso
	match ToolManager.selected_tool:
		DataTypes.Tools.PlantCorn, DataTypes.Tools.PlantTomato:
			EventBus.show_click_animation.emit()
		_:
			EventBus.show_action_warning.emit(wrong_tool_warning)
