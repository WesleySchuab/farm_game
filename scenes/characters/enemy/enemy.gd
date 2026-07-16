## Classe principal do inimigo
## Gerencia o inimigo controlado por IA com máquina de estados
class_name Enemy
extends CharacterBody2D

@onready var hit_component: HitComponent = $HitComponent

## Velocidade de movimentação do inimigo
@export var chase_speed: float = 40.0

## Vida do inimigo
@export var max_health: float = 30.0
var current_health: float = 30.0

## Distância mínima para começar a perseguir o player
@export var chase_distance: float = 150.0

## Distância para atacar o player
@export var attack_distance: float = 50.0

## Direção que o inimigo está olhando
var enemy_direction: Vector2 = Vector2.DOWN

## Referência ao player
var player: Node2D = null

## Variável de controle para o inimigo morrer
var is_dead: bool = false


func _ready() -> void:
	# Busca o player na cena através do grupo
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# Adicionar inimigo ao grupo de inimigos
	add_to_group("enemies")
	
	# Conectar ao sinal de morte do player para parar quando player morre
	if EventBus:
		EventBus.player_died.connect(_on_player_died)


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


## Callback quando o player morre
func _on_player_died() -> void:
	set_physics_process(false)
