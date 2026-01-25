## Componente de dano
## Gerencia o sistema de dano e vida de um objeto
## Rastreia dano acumulado e emite sinal quando o dano máximo é atingido
class_name DamageComponent
extends Node2D

## Quantidade máxima de dano que o objeto pode receber antes de ser destruído/morrer
@export var max_damage = 1

## Quantidade atual de dano acumulado no objeto
@export var current_damage = 0

## Sinal emitido quando o dano máximo é atingido (objeto deve ser destruído/morrer)
signal max_damaged_reached

## Aplica dano ao objeto
## Incrementa o dano atual e mantém dentro dos limites (0 até max_damage)
## Emite o sinal max_damaged_reached quando o dano máximo é atingido
func apply_damage(damage: int )-> void:
	current_damage = clamp(current_damage + damage, 0, max_damage)
	
	if current_damage == max_damage :
		max_damaged_reached.emit()
