extends NodeState

## Estado de Caminhada para NPCs
## Este estado gerencia o comportamento de movimento aleatório do personagem
## utilizando o sistema de navegação do Godot (NavigationAgent2D)

# Referências principais do estado
@export var character: NonPlayableCharacter  # Personagem que será controlado
@export var animated_sprite_2d: AnimatedSprite2D  # Sprite para animação de caminhada
@export var navigation_agent_2d : NavigationAgent2D  # Agente de navegação para pathfinding

# Configuração da velocidade de caminhada
@export var min_speed : float = 5.0  # Velocidade mínima (pixels/segundo)
@export var max_speed : float = 10.0  # Velocidade máxima (pixels/segundo)

# Velocidade atual escolhida aleatoriamente entre min_speed e max_speed
var speed: float

## Método chamado quando o nó é adicionado à cena
func _ready() -> void:
	# Conecta o sinal velocity_computed do NavigationAgent2D
	# Este sinal é emitido quando há evitação de obstáculos ativa
	navigation_agent_2d.velocity_computed.connect(on_safe_velocity_computed)
	
	# Chama character_setup de forma diferida para garantir que
	# todos os nós estejam prontos e o mapa de navegação esteja carregado
	call_deferred("character_setup")

## Configuração inicial do personagem após todos os nós estarem prontos
func character_setup() -> void:
	# Aguarda um frame de física para garantir que o NavigationServer2D
	# já tenha processado e o mapa de navegação esteja disponível
	await get_tree().physics_frame
	
	# Define o primeiro ponto de destino aleatório para o personagem
	set_movement_target()

## Define um novo ponto de destino aleatório para o personagem
func set_movement_target() -> void :
	# Obtém um ponto aleatório válido dentro da malha de navegação (NavigationMesh)
	# Isso garante que o personagem só se mova para áreas navegáveis
	var target_position: Vector2 = NavigationServer2D.map_get_random_point(
		navigation_agent_2d.get_navigation_map(), 
		navigation_agent_2d.navigation_layers, 
		false
	)
	navigation_agent_2d.target_position = target_position
	
	# Define uma velocidade aleatória para este ciclo de caminhada
	# Isso cria variação no movimento, tornando-o mais natural
	speed = randf_range(min_speed, max_speed)

## Callback do ciclo de processo (não utilizado neste estado)
func _on_process(_delta : float) -> void:
	pass


## Callback do ciclo de física - processa o movimento do personagem
func _on_physics_process(_delta : float) -> void:
	# Verifica se o personagem chegou ao destino atual
	if navigation_agent_2d.is_navigation_finished():
		# Incrementa o contador de ciclos de caminhada completados
		character.current_walk_cycle += 1
		# Define um novo alvo aleatório
		set_movement_target()
		return
	
	# Obtém a próxima posição no caminho calculado pelo NavigationAgent
	var target_position: Vector2 = navigation_agent_2d.get_next_path_position()
	
	# Calcula a direção normalizada do personagem até o próximo ponto
	var target_direction : Vector2 = character.global_position.direction_to(target_position)
	
	# Calcula a velocidade desejada multiplicando direção pela velocidade
	var velocity: Vector2 = target_direction * speed
	
	# Verifica se o sistema de evitação de obstáculos está ativo
	if navigation_agent_2d.avoidance_enabled:
		# Espelha o sprite horizontalmente baseado na direção X
		# flip_h = true quando movendo para esquerda (x negativo)
		animated_sprite_2d.flip_h = velocity.x < 0
	
		# Envia a velocidade desejada para o NavigationAgent calcular evitação
		# O resultado será retornado via sinal velocity_computed
		navigation_agent_2d.velocity = velocity
	else:
		# Se evitação desabilitada, aplica a velocidade diretamente
		character.velocity = velocity
	
	# Aplica a velocidade diretamente ao personagem
	# (essa linha sobrescreve a velocity definida acima, pode ser redundante)
	character.velocity = target_direction * speed
	character.move_and_slide()

## Callback acionado quando o NavigationAgent2D calcula uma velocidade segura
## Isso acontece quando o sistema de evitação de obstáculos está ativo
func on_safe_velocity_computed(safe_velocity: Vector2)-> void :
	# Espelha o sprite baseado na direção X da velocidade segura
	animated_sprite_2d.flip_h = safe_velocity.x < 0
	
	# Aplica a velocidade segura (já com evitação calculada) ao personagem
	character.velocity = safe_velocity
	character.move_and_slide()
	
## Verifica condições para transição para outros estados
func _on_next_transitions() -> void:
	# Transita para o estado idle quando completa todos os ciclos de caminhada
	if character.current_walk_cycle == character.walk_cycles:
		# Para o movimento do personagem
		character.velocity = Vector2.ZERO
		# Emite sinal de transição para o estado "idle"
		transition.emit("idle") 


## Chamado quando o estado é ativado
func _on_enter() -> void:
	# Inicia a animação de caminhada quando entra neste estado
	animated_sprite_2d.play("walk")
	# Reseta o contador de ciclos de caminhada
	character.current_walk_cycle = 0


## Chamado quando o estado é desativado
func _on_exit() -> void:
	# Para a animação ao sair do estado de caminhada
	animated_sprite_2d.stop()
