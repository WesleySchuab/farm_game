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

func _ready() -> void:
	# Se conecta ao sinal de morte
	EventBus.player_died.connect(_on_player_died)

## Processa a lógica do estado a cada frame
func _on_process(_delta : float) -> void:
	pass

## Processa a física do movimento a cada frame
## Obtém a direção do input, atualiza a animação correspondente (andar ou correr)
## Atualiza a direção do jogador e move o personagem
func _on_physics_process(_delta : float) -> void:
	
	var direction: Vector2 = GameInputEvents.movement_input()
	
	if not controle_de_animacao_ativo: 
		return # Se o player morreu, não deixa o script rodar mais nada!
		
	# Verifica se a tecla configurada como "run" (Shift) está pressionada E se há movimento
	# Isso previne que a animação de correr toque mesmo se o jogador estiver parado
	var wants_to_run: bool = Input.is_action_pressed("run") and direction != Vector2.ZERO
	
	# Define a velocidade atual e o tipo de animação com base no estado de corrida
	var current_speed: int = run_speed if wants_to_run else speed
	var anim_prefix: String = "run_" if wants_to_run else "walk_"

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
	# animated_sprite_2d.speed_scale = 1.0 # Reseta a escala de velocidade ao sair (se usou o opcional)

func _on_player_died() -> void:
	controle_de_animacao_ativo = false # Desativa o controle normal de andar/correr
	animated_sprite_2d.play("idle_dead")
