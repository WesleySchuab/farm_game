## Estado Idle do inimigo
## Inimigo parado esperando avistar o player
extends NodeState

var enemy: Enemy
var animated_sprite_2d: AnimatedSprite2D
var controle_de_animacao_ativo: bool = true


func _ready() -> void:
	# Conecta ao sinal de morte para parar animações
	if EventBus:
		EventBus.player_died.connect(_on_player_died)


## Executado quando o estado idle é iniciado
func _on_enter() -> void:
	enemy = owner as Enemy
	animated_sprite_2d = enemy.get_node("AnimatedSprite2D")
	
	if animated_sprite_2d:
		animated_sprite_2d.play("mushroom_idle")


## Processa a lógica do estado a cada frame
func _on_process(_delta: float) -> void:
	pass


## Processa a física do estado a cada frame
func _on_physics_process(_delta: float) -> void:
	if not controle_de_animacao_ativo:
		return


## Verifica condições para transição para outros estados
func _on_next_transitions() -> void:
	if enemy == null:
		enemy = owner as Enemy
	
	if not controle_de_animacao_ativo:
		return
	
	# Se o player existe e está próximo, transiciona para Chase
	if enemy.player and enemy.get_distance_to_player() <= enemy.chase_distance:
		# Atualiza o flip para a direção correta antes de começar a perseguir
		var direction = enemy.get_direction_to_player()
		enemy.update_flip(direction)
		transition.emit("chase")


## Callback quando o player morre
func _on_player_died() -> void:
	controle_de_animacao_ativo = false
