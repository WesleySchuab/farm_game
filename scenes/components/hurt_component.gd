## Componente de dano recebido
## Detecta quando um objeto é atingido e emite sinal de dano
class_name HurtComponent

extends Area2D

## Tipo de ferramenta que pode causar dano a este componente
@export var tool: DataTypes.Tools = DataTypes.Tools.AxeWood

## Sinal emitido quando o objeto recebe dano, passando a quantidade de dano como parâmetro
signal hurt 


## Callback chamado quando uma área entra em colisão
## Verifica se a ferramenta do ataque corresponde à ferramenta aceita
## Se corresponder, emite o sinal hurt com o dano do ataque
func _on_area_entered(area: Area2D) -> void:
	var hit_comoponent = area as HitComponent
	if tool == hit_comoponent.current_tool:
		hurt.emit(hit_comoponent.hit_damage)
