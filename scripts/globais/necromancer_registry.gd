# NecromancerRegistry.gd (Configurado como Autoload/Singleton)
extends Node

## Registro global de aparições do Necromante
## Persiste entre fases do jogo e pode ser acessado de qualquer cena

## Total de vezes que o Necromante apareceu no jogo
var total_appearances: int = 0

## Sinal emitido quando o Necromante aparece
signal necromancer_appeared(total: int)

## Sinal emitido quando o Necromante desaparece (invocação concluída ou morte)
signal necromancer_vanished(total: int)


## Incrementa o contador de aparições
func register_appearance() -> void:
	total_appearances += 1
	print("💀 [NECROMANCER REGISTRY] Aparição #", total_appearances, " registrada!")
	necromancer_appeared.emit(total_appearances)


## Retorna o total de aparições
func get_total_appearances() -> int:
	return total_appearances


## Reseta o contador (útil para novo jogo)
func reset() -> void:
	total_appearances = 0
	print("💀 [NECROMANCER REGISTRY] Contador resetado.")
