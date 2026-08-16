## Barreira de rocha colocável pelo jogador
## Bloqueia movimento (StaticBody2D) e pode ser destruída por ataques (machado)
class_name RockBarrier
extends StaticBody2D

## Componente que detecta quando a barreira é atingida
@onready var hurt_component: HurtComponent = $HurtComponent

## Componente que gerencia o dano acumulado da barreira
@onready var damage_component: DamageComponent = $DamageComponent

## Componente de save (persistência entre sessões)
@onready var save_data_component: SaveDataComponent = $SaveDataComponent

## Quantas pedras são devolvidas ao quebrar a barreira
@export var refund_stone: int = 1

## Inicializa a barreira conectando os sinais dos componentes
func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damaged_reached.connect(on_max_damaged_reached)
	_setup_save_data()

## Callback chamado quando a barreira recebe dano
## Aplica o dano recebido ao componente de dano e toca o som de picareta
func on_hurt(hit_damage: int) -> void:
	damage_component.apply_damage(hit_damage)
	AudioManager.play_sfx_at(AudioManager.SFX.PICKAXE_HIT, global_position, -4)

## Callback chamado quando a barreira é destruída
## Devolve as pedras ao inventário e remove a barreira da cena
func on_max_damaged_reached() -> void:
	for i in refund_stone:
		InventoryManager.add_collectable("stone")
	queue_free()

## Cria um SceneDataResource próprio por instância para o save não sobrescrever outras barreiras
func _setup_save_data() -> void:
	if save_data_component == null:
		return
	var resource: SceneDataResource = SceneDataResource.new()
	save_data_component.save_data_resource = resource
