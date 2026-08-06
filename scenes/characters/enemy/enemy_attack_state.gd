## Estado Attack do inimigo
## Inimigo ataca o player
extends NodeState

var enemy: Enemy
var animated_sprite_2d: AnimatedSprite2D

var controle_de_animacao_ativo: bool = true


## Tempo mínimo entre ataques (em segundos)
@export var attack_cooldown: float = 1.5
var time_since_last_attack: float = 0.0

## Tempo mínimo que o inimigo deve permanecer no estado de ataque (evita flickering)
@export var min_attack_duration: float = 0.5
var _time_in_attack: float = 0.0

## Delay (em segundos) antes de ativar o hitbox / lançar projétil após iniciar a animação
## Deve corresponder ao frame de "impacto" da animação de ataque
@export var hitbox_enable_delay: float = 2

## Duração total do estado de ataque (fallback para animações em loop)
## Deve ser >= hitbox_enable_delay + tempo da animação pós-impacto
@export var attack_total_duration: float = 3.0

## Projétil lançado no ataque (ex: BallNecromante). Se null, usa hitbox melee.
@export var projectile_scene: PackedScene = null

## Offset de spawn do projétil (relativo à posição do inimigo)
## Ex: Necromante usa Vector2(5, 0) para alinhar com o sprite no eixo X
@export var projectile_spawn_offset: Vector2 = Vector2.ZERO

## Velocidade do projétil
@export var projectile_speed: float = 150.0

## Flag que controla se a animação de ataque está tocando
var _attack_animation_started: bool = false

## Flag que controla se o ataque (hitbox ou projétil) já foi executado neste ciclo
var _attack_executed: bool = false


func _ready() -> void:
	# Conecta ao sinal de morte
	if EventBus:
		EventBus.player_died.connect(_on_player_died)


## Executado quando o estado attack é iniciado
func _on_enter() -> void:
	# Obtém as referências a cada entrada (consistente com Idle e Chase)
	enemy = owner as Enemy
	if enemy:
		animated_sprite_2d = enemy.get_node("AnimatedSprite2D")
	
	time_since_last_attack = attack_cooldown  # Permite ataque imediatamente
	_time_in_attack = 0.0
	_attack_animation_started = false
	_attack_executed = false
	
	# Toca a animação de ataque PRIMEIRO (wind-up visual)
	if animated_sprite_2d:
		animated_sprite_2d.play("attack")
		_attack_animation_started = true
		print("🔴 [ATTACK STATE] Animação 'attack' iniciada! Hitbox será ativada em %.2fs" % hitbox_enable_delay)
	else:
		print("❌ [ATTACK STATE] ERRO: animated_sprite_2d é null!")
	
	# ⚠️ NÃO ativa o hitbox aqui — será ativado com delay no _on_process
	# para sincronizar com o frame de impacto da animação
	
	# Registra o tempo do ataque para cooldown no Enemy
	if enemy:
		enemy.last_attack_time = Time.get_ticks_msec() / 1000.0

## Processa a lógica do estado a cada frame
func _on_process(delta: float) -> void:
	if enemy and enemy.is_dead:
		return
	
	time_since_last_attack += delta
	_time_in_attack += delta
	
	# Executa o ataque com delay, sincronizado com o frame de impacto da animação
	if not _attack_executed and _time_in_attack >= hitbox_enable_delay:
		if projectile_scene and enemy and enemy.player:
			# Lança projétil na direção do player
			_spawn_projectile()
		elif enemy:
			# Ataque melee (hitbox)
			enemy.enable_hit_box()
		_attack_executed = true
		print("🔴 [ATTACK STATE] Ataque executado! (t=%.2fs)" % _time_in_attack)
	
	# Sai do estado de ataque quando:
	# 1. Tempo mínimo passou E a animação terminou (não-loop), OU
	# 2. Tempo total do ataque passou (fallback para animações em loop como necromante)
	var can_exit_by_animation = _attack_animation_started and animated_sprite_2d and not animated_sprite_2d.is_playing()
	var can_exit_by_timer = _time_in_attack >= attack_total_duration
	
	if _time_in_attack >= min_attack_duration and (can_exit_by_animation or can_exit_by_timer):
		print("🔴 [ATTACK STATE] Saindo! (anim: %s | timer: %s) → Voltando para Chase" % [can_exit_by_animation, can_exit_by_timer])
		transition.emit("chase")


## Lança o projétil na direção do player
func _spawn_projectile() -> void:
	var ball = projectile_scene.instantiate()
	ball.global_position = enemy.global_position + projectile_spawn_offset
	ball.direction = enemy.get_direction_to_player()
	ball.speed = projectile_speed
	enemy.get_parent().add_child(ball)
	print("💀 [ATTACK STATE] Projétil lançado! Offset: ", projectile_spawn_offset)


## Processa a física do estado a cada frame
func _on_physics_process(_delta: float) -> void:
	if enemy and enemy.is_dead:
		return
	if not controle_de_animacao_ativo:
		return
	
	if enemy == null or enemy.player == null:
		return
	
	# Inimigo fica parado enquanto ataca, olhando para o player
	var direction = enemy.get_direction_to_player()
	if direction != Vector2.ZERO:
		enemy.enemy_direction = direction
		# Atualiza o flip durante o ataque
		enemy.update_flip(direction)


## Verifica condições para transição para outros estados
func _on_next_transitions() -> void:
	if enemy == null:
		enemy = owner as Enemy
	
	if enemy and enemy.is_dead:
		return
	
	if not controle_de_animacao_ativo or not enemy.player:
		return
	
	var distance = enemy.get_distance_to_player()
	
	# Emergência: se o player fugiu MUITO longe, interrompe o ataque imediatamente
	if distance > enemy.chase_distance * 2.0:
		print("🔴 [ATTACK STATE] Player fugiu muito longe! (%.2f) → Chase" % distance)
		transition.emit("chase")
		return
	
	# Enquanto a animação de ataque estiver tocando, NÃO transita por distância
	# Isso garante que o frame completo da animação seja visível
	if animated_sprite_2d and animated_sprite_2d.is_playing():
		return
	
	# Animação terminou — agora verifica distâncias normalmente
	print("🔴 [ATTACK STATE] Distância até player: %.2f | Attack Distance: %.2f" % [distance, enemy.attack_distance])
	
	if distance > enemy.chase_distance:
		print("🔴 [ATTACK STATE] Player saiu da zona de chase! → Chase")
		transition.emit("chase")
	elif distance > enemy.attack_distance:
		print("🔴 [ATTACK STATE] Player saiu da zona de ataque! → Chase")
		transition.emit("chase")


## Executado quando o estado é finalizado
func _on_exit() -> void:
	# Desabilita o hitbox via método centralizado do Enemy
	enemy.disable_hit_box()
	
	if animated_sprite_2d:
		animated_sprite_2d.stop()


## Callback quando o player morre
func _on_player_died() -> void:
	controle_de_animacao_ativo = false
