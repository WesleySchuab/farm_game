## Componente de dano recebido
## Detecta quando um objeto é atingido e emite sinal de dano
class_name HurtComponent

extends Area2D

## Tipo de ferramenta que pode causar dano a este componente
@export var tool: DataTypes.Tools = DataTypes.Tools.WaterCrops

## Sinal emitido quando o objeto recebe dano, passando a quantidade de dano como parâmetro
signal hurt

func _ready() -> void:
	monitoring = true
	monitorable = true
	print("🛡️ HurtComponent ready. Tool aceita: ", DataTypes.Tools.keys()[tool], " | Layer: ", collision_layer, " | Mask: ", collision_mask) 


## Callback chamado quando uma área entra em colisão
## Verifica se a ferramenta do ataque corresponde à ferramenta aceita
## Se corresponder, emite o sinal hurt com o dano do ataque
func _on_area_entered(area: Area2D) -> void:
	print("⚠️ HurtComponent detectou area: ", area.name, " | Tipo: ", area.get_class())
	var hit_component = area as HitComponent
	if hit_component == null:
		print("❌ Área não é HitComponent")
		return
	print("✅ É HitComponent! Tool esperada: ", DataTypes.Tools.keys()[tool], " | Tool recebida: ", DataTypes.Tools.keys()[hit_component.current_tool])
	if tool == hit_component.current_tool:
		hurt.emit(hit_component.hit_damage)
		print("🎯 Colisão aconteceu! Tool:", DataTypes.Tools.keys()[tool])
