## Classe principal do jogador
## Gerencia o personagem controlável do jogo
class_name Player
extends CharacterBody2D

## Armazena a direção que o jogador está olhando (UP, DOWN, LEFT, RIGHT)
var player_direction: Vector2

## Ferramenta atualmente equipada pelo jogador
@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
