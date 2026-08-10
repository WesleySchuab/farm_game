class_name BallNecromante
extends Area2D

## Bola mágica lançada pelo Necromante
## Viaja na direção do player e causa dano ao atingir

enum KnockbackMode { PUSH, PULL }

## Dano causado ao player
@export var damage: int = 10

## Modo de knockback: PUSH = empurra na direção da bola | PULL = puxa em direção ao atacante
@export var knockback_mode: KnockbackMode = KnockbackMode.PUSH

## Velocidade do projétil
var speed: float = 150.0

## Direção de movimento (normalizada)
var direction: Vector2 = Vector2.ZERO

## Cena de explosão (GPUParticles2D one-shot) instanciada ao atingir o player
@export var explosion_scene: PackedScene = null


func _ready() -> void:
	set_as_top_level(true)
	$HitComponent.area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if direction != Vector2.ZERO:
		position += direction * speed * delta


## Ao atingir o PlayerHurtComponent, causa dano e se destrói
func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() is Player:
		var player = area.get_parent() as Player
		player.adicionar_vida(-damage)
		
		# Direção do knockback: PUSH = mesma direção da bola | PULL = direção oposta (puxa)
		var knockback_dir := direction if knockback_mode == KnockbackMode.PUSH else -direction
		player.aplicar_knockback(knockback_dir)
		
		print("💀 [BALL NECROMANTE] Atingiu o player! Dano: ", damage, " | Knockback: ", "PUSH" if knockback_mode == KnockbackMode.PUSH else "PULL")
		
		# Instancia a explosão IMEDIATAMENTE na posição da bola
		if explosion_scene:
			var explosion = explosion_scene.instantiate()
			explosion.global_position = global_position
			get_tree().root.add_child(explosion)
		
		queue_free()
