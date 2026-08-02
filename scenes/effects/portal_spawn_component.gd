class_name PortalSpawnComponent
extends Node

## Componente reutilizável de spawn com efeito de portal
## Pode ser anexado a qualquer CharacterBody2D ou Node2D
## para criar um efeito de "emergir de um portal"

## Sinal emitido quando a animação de spawn termina
signal spawn_complete

## Partículas principais do portal (anel/círculo no chão)
@export var portal_particles: GPUParticles2D

## Partículas secundárias do portal (opcional, ex: sparkles)
@export var portal_particles2: GPUParticles2D

## Sprite alvo que será animada (fade-in + scale)
@export var target_sprite: CanvasItem

## Duração total da animação de spawn em segundos
@export var spawn_duration: float = 4.0

## Nós CollisionShape2D a desabilitar durante o spawn
@export var disable_collisions: Array[CollisionShape2D] = []

## Nós a terem physics_process desabilitado durante o spawn
@export var disable_physics_on: Array[Node] = []

## Se o spawn está ativo no momento
var is_spawning: bool = false

## Guarda o modulate.a original do target_sprite
var _original_modulate_a: float = 1.0

## Guarda o scale original do target_sprite
var _original_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	if target_sprite:
		_original_modulate_a = target_sprite.modulate.a
		_original_scale = target_sprite.scale


## Inicia a animação de spawn via portal
## Pode ser chamado manualmente ou via _ready()
func play_spawn() -> void:
	if is_spawning:
		return
	
	is_spawning = true
	
	# Desabilita física em nós configurados
	for node in disable_physics_on:
		if node is CharacterBody2D or node is AnimatableBody2D or node is RigidBody2D:
			node.set_physics_process(false)
	
	# Desabilita colisões configuradas
	for shape in disable_collisions:
		shape.disabled = true
	
	# Estado inicial: invisível e scale 0
	if target_sprite:
		target_sprite.modulate.a = 0.0
		target_sprite.scale = Vector2.ZERO
	
	# Ativa partículas do portal
	if portal_particles:
		portal_particles.emitting = true
		portal_particles.restart()
	
	if portal_particles2:
		portal_particles2.emitting = true
		portal_particles2.restart()
	
	# --- Animação via Tween ---
	var tween = create_tween()
	tween.set_parallel(true)
	
	if target_sprite:
		# Scale: 0 → 1.1 → 1.0 (efeito "pop")
		tween.tween_property(target_sprite, "scale", Vector2(1.1, 1.1), spawn_duration * 0.6) \
			.set_delay(spawn_duration * 0.4)
		tween.tween_property(target_sprite, "scale", Vector2(1.0, 1.0), spawn_duration * 0.3) \
			.set_delay(spawn_duration * 1.0)
		
		# Fade in: 0 → original_alpha
		tween.tween_property(target_sprite, "modulate:a", _original_modulate_a, spawn_duration * 0.8) \
			.set_delay(spawn_duration * 0.6)
	
	# Callback de conclusão
	tween.tween_callback(_on_spawn_finished).set_delay(spawn_duration)


## Callback interno quando a animação termina
func _on_spawn_finished() -> void:
	is_spawning = false
	
	# Para as partículas (vão morrer naturalmente conforme lifetime)
	if portal_particles:
		portal_particles.emitting = false
	if portal_particles2:
		portal_particles2.emitting = false
	
	# Reativa física
	for node in disable_physics_on:
		if node is CharacterBody2D or node is AnimatableBody2D or node is RigidBody2D:
			node.set_physics_process(true)
	
	# Emite sinal para quem conectou
	spawn_complete.emit()
