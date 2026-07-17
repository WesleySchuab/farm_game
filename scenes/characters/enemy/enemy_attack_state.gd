## Estado Attack do inimigo
## Inimigo ataca o player
extends NodeState

var enemy: Enemy
var animated_sprite_2d: AnimatedSprite2D
var hit_component_collision_shape: CollisionShape2D
var controle_de_animacao_ativo: bool = true

## Tempo mínimo entre ataques (em segundos)
@export var attack_cooldown: float = 1.5
var time_since_last_attack: float = 0.0


func _ready() -> void:
	# Conecta ao sinal de morte
	if EventBus:
		EventBus.player_died.connect(_on_player_died)


## Executado quando o estado attack é iniciado
func _on_enter() -> void:
	enemy = owner as Enemy
	animated_sprite_2d = enemy.get_node("AnimatedSprite2D")
	hit_component_collision_shape = enemy.get_node("HitComponent/CollisionShape2D")
	
	time_since_last_attack = attack_cooldown  # Permite ataque imediatamente
	
	if animated_sprite_2d:
		animated_sprite_2d.play("mushroom_attack_right")
		#sprint("🔴 [ATTACK STATE] Iniciando ataque do inimigo")
	
	# Habilita a colisão do componente de ataque
	if hit_component_collision_shape:
		hit_component_collision_shape.disabled = false
		#print("🔴 [ATTACK STATE] HitComponent habilitado - Collision Shape: ", hit_component_collision_shape)
	else:
		print("❌ [ATTACK STATE] ERRO: HitComponent/CollisionShape2D não encontrado!")


## Processa a lógica do estado a cada frame
func _on_process(delta: float) -> void:
	# Incrementa o cooldown
	time_since_last_attack += delta


## Processa a física do estado a cada frame
func _on_physics_process(_delta: float) -> void:
	if not controle_de_animacao_ativo:
		return
	
	if enemy == null or enemy.player == null:
		return
	
	# Inimigo fica parado enquanto ataca, olhando para o player
	var direction = enemy.get_direction_to_player()
	if direction != Vector2.ZERO:
		enemy.enemy_direction = direction


## Verifica condições para transição para outros estados
func _on_next_transitions() -> void:
	if enemy == null:
		enemy = owner as Enemy
	
	if not controle_de_animacao_ativo or not enemy.player:
		return
	
	var distance = enemy.get_distance_to_player()
	print("🔴 [ATTACK STATE] Distância até player: %.2f | Attack Distance: %.2f" % [distance, enemy.attack_distance])
	
	# Se o player se afastou além da distância de perseguição, volta a perseguir
	if distance > enemy.chase_distance:
		print("🔴 [ATTACK STATE] Player muito longe! Transitando para Chase")
		transition.emit("chase")
	
	# Se o player saiu da zona de ataque mas ainda está perto, persegue
	elif distance > enemy.attack_distance:
		print("🔴 [ATTACK STATE] Player saiu da zona de ataque! Transitando para Chase")
		transition.emit("chase")


## Executado quando o estado é finalizado
func _on_exit() -> void:
	# Desabilita a colisão do componente de ataque
	if hit_component_collision_shape:
		hit_component_collision_shape.disabled = true
	
	if animated_sprite_2d:
		animated_sprite_2d.stop()


## Callback quando o player morre
func _on_player_died() -> void:
	controle_de_animacao_ativo = false
