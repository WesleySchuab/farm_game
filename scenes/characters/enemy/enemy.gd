class_name Enemy
extends CharacterBody2D

## Classe principal do inimigo
## Gerencia o inimigo controlado por IA com máquina de estados

@onready var hit_component: HitComponent = $HitComponent

## Velocidade de movimentação do inimigo
@export var chase_speed: float = 40.0

## Vida do inimigo
@export var max_health: float = 30.0
var current_health: float = 30.0

## Distância mínima para começar a perseguir o player
@export var chase_distance: float = 150.0

## Distância para atacar o player
@export var attack_distance: float = 35.0

## Direção que o inimigo está olhando
var enemy_direction: Vector2 = Vector2.DOWN

## Referência ao player
var player: Node2D = null

## Variável de controle para o inimigo morrer
var is_dead: bool = false

## Controla se a sprite está flipada
var is_flipped: bool = false

## Referência à sprite animada
var animated_sprite_2d: AnimatedSprite2D

## Referência ao collision shape do hit component
var hit_component_collision_shape: CollisionShape2D


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
	
	# Obter referência à sprite
	animated_sprite_2d = get_node("AnimatedSprite2D")
	
	# Obter referência ao collision shape do hit component
	hit_component_collision_shape = get_node("HitComponent/HitComponentCollisionShape2D")
	
	print("👹 [ENEMY] Inimigo inicializado - Chase Distance: ", chase_distance, " | Attack Distance: ", attack_distance)


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


## Função para morrer
func morrer() -> void:
	is_dead = true
	print("👹 Inimigo derrotado!")
	
	# Emite sinal de morte (opcional, para futuras conquistas/XP)
	#EventBus.enemy_died.emit()
	
	set_physics_process(false)
	queue_free()


## Funcao para flipar a sprite e o hit component
## Inverte a sprite quando a direção muda
func update_flip(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	
	# Se o inimigo está se movendo para a direita e está flipado, desflipa
	if direction.x < 0 and is_flipped:
		is_flipped = false
		if animated_sprite_2d:
			animated_sprite_2d.flip_h = false
		# Inverte a posição X do hit component para direita
		if hit_component_collision_shape:
			hit_component_collision_shape.position.x = -26
		print("👹 [ENEMY] Desflipado para direita - HitBox position: -26")
	
	# Se o inimigo está se movendo para a esquerda e não está flipado, flipa
	elif direction.x > 0 and not is_flipped:
		is_flipped = true
		if animated_sprite_2d:
			animated_sprite_2d.flip_h = true
		# Inverte a posição X do hit component para esquerda
		if hit_component_collision_shape:
			hit_component_collision_shape.position.x = 26
		print("👹 [ENEMY] Flipado para esquerda - HitBox position: 26")
		


## Callback quando o player morre
func _on_player_died() -> void:
	set_physics_process(false)
