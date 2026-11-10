extends Sprite2D

## Componente que detecta quando a árvore é atingida
@onready var hurt_component: HurtComponent = $HurtComponent


## Componente que gerencia o dano acumulado da árvore
@onready var damage_component: DamageComponent = $DamageComponent


var log_scene = preload("res://scenes/objects/tree/log.tscn")
var _shake_tween: Tween

## Inicializa a árvore conectando os sinais dos componentes
## Conecta o sinal de dano recebido e o sinal de dano máximo atingido
func _ready() -> void:
	# Duplica o material para que cada instância tenha seu próprio shader
	material = material.duplicate()
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damaged_reached.connect(on_max_damaged_reached)

## Callback chamado quando a árvore recebe dano
## Aplica o dano recebido ao componente de dano
func on_hurt(hit_damage: int )-> void:
	damage_component.apply_damage(hit_damage)
	AudioManager.play_sfx_at(AudioManager.SFX.AXE_HIT, global_position, -4)
	shake_tree()


func shake_tree() -> void:
	if _shake_tween != null and _shake_tween.is_running():
		_shake_tween.kill()
	material.set_shader_parameter("shake_intensity", 1.5)
	_shake_tween = create_tween()
	_shake_tween.tween_interval(0.5)
	_shake_tween.tween_callback(func() -> void:
		material.set_shader_parameter("shake_intensity", 0.0)
	)

## Callback chamado quando o dano máximo é atingido
## Remove a árvore da cena (destrói o objeto)
func on_max_damaged_reached() -> void:
	call_deferred("add_log_scenes")
	print("max damaged reached")
	queue_free()
	
func add_log_scenes()-> void :
	var drop_count: int = 4
	for i in drop_count:
		var log_instance = log_scene.instantiate() as Node2D
		get_parent().add_child(log_instance)
		log_instance.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
