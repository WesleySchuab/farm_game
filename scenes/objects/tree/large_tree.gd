extends Sprite2D

## Componente que detecta quando a árvore é atingida
@onready var hurt_component: HurtComponent = $HurtComponent


## Componente que gerencia o dano acumulado da árvore
@onready var damage_component: DamageComponent = $DamageComponent


var log_scene = preload("res://scenes/objects/tree/log.tscn")

## Inicializa a árvore conectando os sinais dos componentes
## Conecta o sinal de dano recebido e o sinal de dano máximo atingido
func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damaged_reached.connect(on_max_damaged_reached)

## Callback chamado quando a árvore recebe dano
## Aplica o dano recebido ao componente de dano
func on_hurt(hit_damage: int )-> void:
	damage_component.apply_damage(hit_damage)

## Callback chamado quando o dano máximo é atingido
## Remove a árvore da cena (destrói o objeto)
func on_max_damaged_reached() -> void:
	call_deferred("add_log_scenes")
	print("max damaged reached")
	queue_free()
	
func add_log_scenes()-> void :
	var log_instance = log_scene.instantiate() as Node2D
	log_instance.global_position = global_position
	get_parent().add_child(log_instance)
