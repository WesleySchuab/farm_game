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

## Delay (em segundos) antes de ativar o hitbox após iniciar a animação
## Deve corresponder ao frame de "impacto" da animação de ataque
@export var hitbox_enable_delay: float = 2

## Flag que controla se a animação de ataque está tocando
var _attack_animation_started: bool = false

## Flag que controla se o hitbox já foi ativado neste ataque
var _hitbox_enabled: bool = false


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
	_hitbox_enabled = false
	
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
	time_since_last_attack += delta
	_time_in_attack += delta
	
	# Ativa o hitbox com delay, sincronizado com o frame de impacto da animação
	if not _hitbox_enabled and _time_in_attack >= hitbox_enable_delay:
		if enemy:
			enemy.enable_hit_box()
			_hitbox_enabled = true
			print("🔴 [ATTACK STATE] Hitbox ATIVADA no frame de impacto! (t=%.2fs)" % _time_in_attack)
	
	# Quando a animação de ataque terminar (não-loop), volta a perseguir
	# Isso permite que o inimigo ataque novamente após o cooldown
	if _attack_animation_started and animated_sprite_2d and not animated_sprite_2d.is_playing():
		print("🔴 [ATTACK STATE] Animação terminou! Voltando para Chase")
		transition.emit("chase")


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
		# Atualiza o flip durante o ataque
		enemy.update_flip(direction)


## Verifica condições para transição para outros estados
func _on_next_transitions() -> void:
	if enemy == null:
		enemy = owner as Enemy
	
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
