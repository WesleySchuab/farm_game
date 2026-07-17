class_name InteractableComponents
extends Area2D

## Componente de interação
## Detecta quando um corpo entra ou sai da área de interação
## Emite sinais para ativar/desativar a possibilidade de interação

## Sinal emitido quando um corpo entra na área de interação
signal interactable_activated

## Sinal emitido quando um corpo sai da área de interação
signal interactable_deactivated


## Callback chamado quando um corpo físico entra na área
## Emite sinal indicando que a interação foi ativada
func _on_body_entered(body: Node2D) -> void:
	interactable_activated.emit()


## Callback chamado quando um corpo físico sai da área
## Emite sinal indicando que a interação foi desativada
func _on_body_exited(body: Node2D) -> void:
	interactable_deactivated.emit()
