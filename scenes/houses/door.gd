## Script de controle da porta
## Gerencia a animação e colisão da porta baseado na interação do jogador
extends StaticBody2D

## Referência ao sprite animado da porta
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

## Referência à forma de colisão da porta
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

## Referência ao componente de interação
@onready var interactable_component: InteractableComponents = $InteractableComponent

## Inicializa a porta conectando os sinais de interação
## Conecta callbacks para quando o jogador entra/sai da área de interação
func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	
## Callback chamado quando o jogador entra na área da porta
## Abre a porta e muda a camada de colisão para permitir passagem
func on_interactable_activated() -> void:
	animated_sprite_2d.play("open_door")
	collision_layer = 2

## Callback chamado quando o jogador sai da área da porta
## Fecha a porta e restaura a camada de colisão para bloquear passagem
func on_interactable_deactivated() -> void:
	animated_sprite_2d.play("close_door")
	collision_layer = 1
