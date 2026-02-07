## Classe principal do jogador
## Gerencia o personagem controlável do jogo
class_name Player
extends CharacterBody2D

@onready var hit_component: HitComponent = $HitComponent

## Armazena a direção que o jogador está olhando (UP, DOWN, LEFT, RIGHT)
var player_direction: Vector2

## Ferramenta atualmente equipada pelo jogador
@export var current_tool: DataTypes.Tools = DataTypes.Tools.None

func _ready() -> void:
	ToolManager.tool_selected.connect(on_tool_selected)
	
func on_tool_selected(tool :DataTypes.Tools)-> void:
	current_tool = tool
	hit_component.current_tool = tool
