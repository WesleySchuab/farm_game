## Script da árvore pequena
## Gerencia o dano recebido e destruição da árvore quando o dano máximo é atingido
extends Sprite2D

## Componente que detecta quando a árvore é atingida
@onready var hurt_component: HurtComponent = $HurtComponent

## Componente que gerencia o dano acumulado da árvore
@onready var damage_component: DamageComponent = $DamageComponent

var stone_scene = preload("res://scenes/objects/rocks/stone.tscn")

## Inicializa a árvore conectando os sinais dos componentes
## Conecta o sinal de dano recebido e o sinal de dano máximo atingido
func _ready() -> void:
	# Duplica o material para que cada instância tenha seu próprio shader
	#material = material.duplicate()
	
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damaged_reached.connect(on_max_damaged_reached)

## Callback chamado quando a árvore recebe dano
## Aplica o dano recebido ao componente de dano
func on_hurt(hit_damage: int )-> void:
	damage_component.apply_damage(hit_damage)
	# Inicia a animação de tremor
	material.set_shader_parameter("shake_intensity", 0.4)
	
	# Aguarda e depois para a animação
	await get_tree().create_timer(0.5).timeout
	material.set_shader_parameter("shake_intensity", 0.0)

## Callback chamado quando o dano máximo é atingido
## Remove a árvore da cena (destrói o objeto)
func on_max_damaged_reached() -> void:
	call_deferred("add_stone_scenes")
	print("max damaged reached")
	queue_free()

## Adiciona uma cena de tronco (log) na posição da pedra quando ela é destruída
## Instancia a cena pré-carregada e a adiciona ao pai na mesma posição global
func add_stone_scenes()-> void :
	# Instancia a cena do tronco/pedra
	var stone_instance = stone_scene.instantiate() as Node2D
	# Define a posição global da instância para ser a mesma da pedra atual
	stone_instance.global_position = global_position
	# Adiciona a instância como filha do nó pai
	get_parent().add_child(stone_instance)
	
