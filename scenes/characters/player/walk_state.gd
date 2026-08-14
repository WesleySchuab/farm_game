## Estado de caminhada e corrida do jogador
## Gerencia movimento, animações e transições enquanto o jogador está andando ou correndo
extends NodeState

## Referência ao jogador
@export var player : Player

## Referência ao componente de sprite animado
@export var animated_sprite_2d : AnimatedSprite2D

## Velocidade de movimento base (caminhada) em pixels por segundo
@export var speed : int = 50

## Velocidade de corrida em pixels por segundo
@export var run_speed : int = 90

# Dentro do SEU script de transições:
var controle_de_animacao_ativo: bool = true

# 🔊 Timer de passos
var _footstep_timer: float = 0.0
const FOOTSTEP_WALK_INTERVAL: float = 0.45
const FOOTSTEP_RUN_INTERVAL: float = 0.28

func _ready() -> void:
	# Se conecta ao sinal de morte
	EventBus.player_died.connect(_on_player_died)

## Processa a lógica do estado a cada frame
func _on_process(delta : float) -> void:
	# 🔊 Passos: lê input DIRETO (não depende de static direction atrasada)
	var moving: bool = (
		Input.is_action_pressed("walk_left") or
		Input.is_action_pressed("walk_right") or
		Input.is_action_pressed("walk_up") or
		Input.is_action_pressed("walk_down")
	)
	if moving:
		var wants_to_run: bool = Input.is_action_pressed("run")
		var interval: float = FOOTSTEP_RUN_INTERVAL if wants_to_run else FOOTSTEP_WALK_INTERVAL
		_footstep_timer += delta
		if _footstep_timer >= interval:
			_footstep_timer = 0.0
			var sfx = player.get_node_or_null("SFXComponent")
			if sfx:
				sfx.footstep_triggered.emit()
	else:
		_footstep_timer = 0.0

## Processa a física do movimento a cada frame
## Obtém a direção do input, atualiza a animação correspondente (andar ou correr)
## Atualiza a direção do jogador e move o personagem
func _on_physics_process(_delta : float) -> void:
	
	# ⏸️ Congelado (evento/cutscene) — não se move
	if not player.movement_enabled:
		player.velocity = Vector2.ZERO
		return

	var direction: Vector2 = GameInputEvents.movement_input()
	
	if not controle_de_animacao_ativo: 
		return # Se o player morreu, não deixa o script rodar mais nada!
	
	# ⏸️ KNOCKBACK ATIVO — não processa movimento, mostra idle
	if player.knockback_velocity != Vector2.ZERO:
		if player.current_tool == DataTypes.Tools.Crossbow:
			var anim: String = "crossbow_front_idle"
			match player.player_direction:
				Vector2.UP: anim = "crossbow_back_idle"
				Vector2.DOWN: anim = "crossbow_front_idle"
				Vector2.LEFT: anim = "crossbow_left_idle"
				Vector2.RIGHT: anim = "crossbow_right_idle"
			if animated_sprite_2d.animation != anim:
				animated_sprite_2d.play(anim)
		else:
			var anim: String = "idle_front"
			match player.player_direction:
				Vector2.UP: anim = "idle_back"
				Vector2.DOWN: anim = "idle_front"
				Vector2.LEFT: anim = "idle_left"
				Vector2.RIGHT: anim = "idle_right"
			if animated_sprite_2d.animation != anim:
				animated_sprite_2d.play(anim)
		return
	
	# Verifica se a tecla configurada como "run" (Shift) está pressionada E se há movimento
	# Isso previne que a animação de correr toque mesmo se o jogador estiver parado
	var wants_to_run: bool = Input.is_action_pressed("run") and direction != Vector2.ZERO
	
	# Define a velocidade atual e o tipo de animação com base no estado de corrida
	var current_speed: int = run_speed if wants_to_run else speed
	var anim_prefix: String = "run_" if wants_to_run else "walk_"
	
	# Usa prefixo "crossbow_" quando a besta está equipada para não "sumir" a arma
	if player.current_tool == DataTypes.Tools.Crossbow:
		anim_prefix = "crossbow_" + anim_prefix

	# Aplica a animação correta baseada na direção e se está correndo ou andando
	var target_animation: String = ""
	if direction == Vector2.UP:
		target_animation = anim_prefix + "back"
	elif direction == Vector2.DOWN:
		target_animation = anim_prefix + "front"
	elif direction == Vector2.LEFT:
		target_animation = anim_prefix + "left"
	elif direction == Vector2.RIGHT:
		target_animation = anim_prefix + "right" # Exemplo: animação de frente para a direita, use a correta se tiver.

	# Só muda a animação se for diferente da atual para evitar trepidações
	if animated_sprite_2d.animation != target_animation:
		# Se estivermos mudando para corrida ou de volta para caminhada,
		# reiniciamos a animação do zero para um começo "limpo"
		if animated_sprite_2d.animation.begins_with("walk_") and wants_to_run:
			animated_sprite_2d.play(target_animation)
			animated_sprite_2d.frame = 0 # Reinicia o frame
		elif animated_sprite_2d.animation.begins_with("run_") and not wants_to_run:
			animated_sprite_2d.play(target_animation)
			animated_sprite_2d.frame = 0 # Reinicia o frame
		else:
			animated_sprite_2d.play(target_animation)

	# (Opcional) Ajusta a velocidade da animação dinamicamente para corresponder à velocidade de movimento
	# Isso faz a animação parecer muito mais fluida.
	# A proporção de 1.0 (velocidade padrão) deve ser para a velocidade de caminhada.
	# Quando correr, a animação vai acelerar proporcionalmente.
	# if wants_to_run:
	# 	animated_sprite_2d.speed_scale = float(run_speed) / float(speed)
	# else:
	# 	animated_sprite_2d.speed_scale = 1.0
		
	if direction != Vector2.ZERO:
		player.player_direction = direction
		
	player.velocity = direction * current_speed
	player.move_and_slide()

## Verifica condições para transição para outros estados
func _on_next_transitions() -> void:
	# ⏸️ KNOCKBACK ATIVO — não muda de estado
	if player.knockback_velocity != Vector2.ZERO:
		return
	
	# ⏸️ Congelado — volta para idle
	if not player.movement_enabled:
		transition.emit("idle")
		return

	if !GameInputEvents.movement_input():
		transition.emit("idle")
	if player.current_tool == DataTypes.Tools.AxeWood && GameInputEvents.use_tool():
		transition.emit("Chopping")

## Executado quando o estado é iniciado
func _on_enter() -> void:
	pass

## Executado quando o estado é finalizado
func _on_exit() -> void:
	animated_sprite_2d.stop()
	_footstep_timer = 0.0
	AudioManager.stop_all_2d()
	# animated_sprite_2d.speed_scale = 1.0 # Reseta a escala de velocidade ao sair (se usou o opcional)

func _on_player_died() -> void:
	controle_de_animacao_ativo = false # Desativa o controle normal de andar/correr
	animated_sprite_2d.play("idle_dead")
