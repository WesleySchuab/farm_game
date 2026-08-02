class_name Enemy
extends CharacterBody2D

## Classe principal do inimigo
## Gerencia o inimigo controlado por IA com máquina de estados

@onready var hit_component: HitComponent = $HitComponent

## Componente que detecta quando o inimigo é atingido por flechas (Crossbow)
@onready var hurt_component: HurtComponent = $HurtComponent

## Velocidade de movimentação do inimigo
@export var chase_speed: float = 40.0

## Vida do inimigo
@export var max_health: float = 30.0
var current_health: float = 30.0

## Distância mínima para começar a perseguir o player
@export var chase_distance: float = 150.0

## Distância para atacar o player
@export var attack_distance: float = 40.0

## Direção que o inimigo está olhando
var enemy_direction: Vector2 = Vector2.DOWN

## Referência ao player
var player: Node2D = null

## Variável de controle para o inimigo morrer
var is_dead: bool = false

## Controla se a sprite está flipada
var is_flipped: bool = false

## Orientação padrão do sprite: true = olha para direita, false = olha para esquerda
## MushMario: false (sprite olha pra esquerda) | Necromante: true (sprite olha pra direita)
@export var sprite_faces_right: bool = true

## Referência à sprite animada
var animated_sprite_2d: AnimatedSprite2D

## Referência ao collision shape do hit component
var hit_component_collision_shape: CollisionShape2D

## Posição padrão do hitbox (usada para reset)
var _hitbox_default_position: Vector2 = Vector2.ZERO

# --- SISTEMA DE SPAWN COM PORTAL ---
## Componente reutilizável de spawn via portal
@onready var portal_spawn_component: PortalSpawnComponent = $PortalSpawnComponent

## Se o inimigo está na animação de spawn (começa true para evitar que o idle toque animação antes do spawn)
var _is_spawning: bool = true

## Tempo do último ataque (usado para cooldown entre ataques)
var last_attack_time: float = -9999.0

## Tempo de cooldown entre ataques consecutivos
@export var attack_cooldown: float = 1.5


func _ready() -> void:
	# Busca o player na cena através do grupo
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("👹 [ENEMY] Player encontrado: ", player.name)
	else:
		print("❌ [ENEMY] Player NÃO encontrado!")
	
	# Adicionar inimigo ao grupo de inimigos
	add_to_group("enemies")
	
	# Conectar ao sinal de morte do player para parar quando player morre
	if EventBus:
		EventBus.player_died.connect(_on_player_died)
	
	# Conecta ao sinal de dano recebido (ex: flechas da besta)
	hurt_component.hurt.connect(on_hurt)
	
	# Obter referência à sprite
	animated_sprite_2d = get_node("AnimatedSprite2D")
	
	# Obter referência ao collision shape do hit component
	hit_component_collision_shape = get_node("HitComponent/HitComponentCollisionShape2D")
	_hitbox_default_position = hit_component_collision_shape.position
	
	# Configura o componente de spawn (se existir)
	if portal_spawn_component:
		portal_spawn_component.spawn_complete.connect(_on_spawn_complete)
		portal_spawn_component.play_spawn()
	else:
		# Sem portal: libera o idle imediatamente e toca animação
		_is_spawning = false
		if animated_sprite_2d:
			animated_sprite_2d.play("idle")
	
	print("👹 [ENEMY] Inimigo inicializado - Chase Distance: ", chase_distance, " | Attack Distance: ", attack_distance)


## Toca a animação do inimigo emergindo de um portal (delega ao PortalSpawnComponent)
func _play_spawn_animation() -> void:
	if portal_spawn_component:
		portal_spawn_component.play_spawn()
		_is_spawning = true


## Callback chamado quando a animação de spawn termina
func _on_spawn_complete() -> void:
	_is_spawning = false
	
	# Toca a animação idle após o fade-in do portal
	if animated_sprite_2d:
		animated_sprite_2d.play("idle")
	
	# Reativa colisões
	if hit_component_collision_shape:
		hit_component_collision_shape.disabled = true  # fica desabilitado até o ataque
	
	if hurt_component:
		var hurt_shape = hurt_component.get_node_or_null("CollisionShape2D")
		if hurt_shape:
			hurt_shape.disabled = false
	
	print("👹 [ENEMY] Spawn completo! Inimigo ativo.")


## Habilita o hitbox de ataque
## Deve ser chamado pelo AttackState no _on_enter()
func enable_hit_box() -> void:
	if hit_component_collision_shape == null:
		return
	# Aplica o flip atual (posição X correta baseada na direção)
	_apply_hitbox_flip_position()
	hit_component_collision_shape.disabled = false


## Desabilita o hitbox de ataque e reseta posição
## Deve ser chamado pelo AttackState no _on_exit() e pelo ChaseState
func disable_hit_box() -> void:
	if hit_component_collision_shape == null:
		return
	hit_component_collision_shape.disabled = true
	hit_component_collision_shape.position = _hitbox_default_position


## Aplica a posição X do hitbox baseada no flip atual e na orientação padrão do sprite (uso interno)
func _apply_hitbox_flip_position() -> void:
	if hit_component_collision_shape == null:
		return
	
	# Determina para qual lado o personagem está REALMENTE olhando
	# sprite_faces_right XOR is_flipped: quando um é true e o outro false, o personagem olha pra direita
	var actually_facing_right: bool = (sprite_faces_right != is_flipped)
	
	if actually_facing_right:
		hit_component_collision_shape.position.x = 26
	else:
		hit_component_collision_shape.position.x = -26


## Calcula a distância até o player
func get_distance_to_player() -> float:
	if player == null:
		return 999999.0
	return global_position.distance_to(player.global_position)


## Calcula a direção até o player
func get_direction_to_player() -> Vector2:
	if player == null:
		return Vector2.ZERO
	return (player.global_position - global_position).normalized()


## Função para adicionar vida
func adicionar_vida(quantidade: float) -> void:
	current_health = clampf(current_health + quantidade, 0.0, max_health)
	
	if current_health <= 0.0:
		morrer()


## Callback chamado quando o HurtComponent recebe dano (ex: flecha da besta)
func on_hurt(hit_damage: int) -> void:
	print("👹 [ENEMY] Recebeu ", hit_damage, " de dano! Vida atual: ", current_health)
	adicionar_vida(-hit_damage)


## Função para morrer
func morrer() -> void:
	is_dead = true
	print("👹 Inimigo derrotado!")
	
	# Emite sinal de morte (opcional, para futuras conquistas/XP)
	#EventBus.enemy_died.emit()
	
	set_physics_process(false)
	queue_free()


## Funcao para flipar a sprite e o hit component
## Inverte a sprite quando a direção muda, respeitando a orientação padrão do sprite
func update_flip(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	
	var moving_right: bool = direction.x > 0
	
	# Determina se deve flipar baseado na direção E na orientação padrão do sprite
	var should_flip: bool
	if sprite_faces_right:
		# Sprite padrão olha pra direita → flipa ao mover pra esquerda
		should_flip = not moving_right
	else:
		# Sprite padrão olha pra esquerda → flipa ao mover pra direita
		should_flip = moving_right
	
	# Só aplica se houve mudança no estado de flip
	if should_flip != is_flipped:
		is_flipped = should_flip
		if animated_sprite_2d:
			animated_sprite_2d.flip_h = should_flip
		_apply_hitbox_flip_position()


## Callback quando o player morre
func _on_player_died() -> void:
	set_physics_process(false)
