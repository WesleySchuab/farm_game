## Componente de ataque
## Detecta colisões de ataque e gerencia o dano causado
class_name HitComponent
extends Area2D

## Tipo de ferramenta associada a este componente de ataque
@export var current_tool : DataTypes.Tools = DataTypes.Tools.AxeWood

## Quantidade de dano que este ataque causa
@export	var hit_damage : int = 1
