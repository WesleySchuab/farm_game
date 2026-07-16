## Estado Chase do inimigo
## Inimigo persegue o player
extends NodeState

var enemy: Enemy
var animated_sprite_2d: AnimatedSprite2D
var controle_de_animacao_ativo: bool = true


func _ready() -> void:
	# Conecta ao sinal de morte
	if EventBus:
		EventBus.player_died.connect(_on_player_died)


## Executado quando o estado chase é iniciado
func _on_enter() -> void:
	enemy = owner as Enemy
	animated_sprite_2d = enemy.get_node("AnimatedSprite2D")
	
	if animated_sprite_2d:
		animated_sprite_2d.play("mushroom_run")


## Processa a lógica do estado a cada frame
func _on_process(_delta: float) -> void:
	pass


## Processa a física do estado a cada frame
## Calcula direção até o player e se move
func _on_physics_process(_delta: float) -> void:
	if not controle_de_animacao_ativo:
		return
	
	if enemy == null or enemy.player == null:
		return
	
	# Calcula direção até o player
	var direction = enemy.get_direction_to_player()
	
	# Atualiza a direção que o inimigo está olhando
	if direction != Vector2.ZERO:
		enemy.enemy_direction = direction
	
	# Aplica velocidade e move
	enemy.velocity = direction * enemy.chase_speed
	enemy.move_and_slide()


## Verifica condições para transição para outros estados
func _on_next_transitions() -> void:
	if enemy == null:
		enemy = owner as Enemy
	
	if not controle_de_animacao_ativo or not enemy.player:
		return
	
	var distance = enemy.get_distance_to_player()
	
	# Se o player está muito perto, transiciona para Attack
	if distance <= enemy.attack_distance:
		transition.emit("attack")
	
	# Se o player se afastou muito, volta para Idle
	elif distance > enemy.chase_distance * 1.5:
		transition.emit("idle")


## Callback quando o player morre
func _on_player_died() -> void:
	controle_de_animacao_ativo = false
