class_name HitComponent
extends Area2D

## Componente de ataque
## Detecta colisões de ataque e gerencia o dano causado

## Tipo de ferramenta associada a este componente de ataque
@export var current_tool : DataTypes.Tools = DataTypes.Tools.AxeWood

## Quantidade de dano que este ataque causa
@export var hit_damage : int = 1

func _ready() -> void:
	monitoring = true
	monitorable = true
	print("⚔️ HitComponent ready. Tool: ", DataTypes.Tools.keys()[current_tool], " | Layer: ", collision_layer, " | Mask: ", collision_mask)
	
	# Conectar sinais de colisão para debug
	area_entered.connect(_on_hit_area_entered)


## Debug de colisões
func _on_hit_area_entered(area: Area2D) -> void:
	print("⚔️ [HIT COMPONENT] Colisão detectada com: ", area.name, " | Tipo: ", area.get_class())
