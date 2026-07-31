class_name Player
extends CharacterBody2D

## Classe principal do jogador
## Gerencia o personagem controlável do jogo
@onready var hit_component: HitComponent = $HitComponent

@export var max_health: float = 100.0
var current_health: float = 100.0

## Armazena a direção que o jogador está olhando (UP, DOWN, LEFT, RIGHT)
var player_direction: Vector2

## Ferramenta atualmente equipada pelo jogador
@export var current_tool: DataTypes.Tools = DataTypes.Tools.None

# Variável de controle para o player não ficar morrendo de fome em loop a cada frame
var is_dead: bool = false

# --- SISTEMA DE KNOCKBACK ---
## Velocidade atual do knockback — usada por outros scripts para detectar se está ativo
var knockback_velocity: Vector2 = Vector2.ZERO

## Força do impulso em pixels/segundo. Ajustável no Inspector.
@export var knockback_force: float = 400.0

## Duração do knockback em segundos. Ajustável no Inspector.
@export var knockback_duration: float = 0.2

## Timer interno em segundos. Controla por quanto tempo o knockback dura.
var _knockback_timer: float = 0.0

func _ready() -> void:
	# Avisa o EventBus logo no início para a barra começar cheia
	# Usamos 'callable.call_deferred' para garantir que a barra já exista na tela antes de enviar o valor
	EventBus.player_health_changed.emit.call_deferred(current_health, max_health)
	current_health = max_health
	
		
	# Conecta ao gerenciador de tempo para a vida descer com o passar das horas
	if DayAndNightCycleManager:
		DayAndNightCycleManager.time_tick.connect(_on_time_tick)
		
	ToolManager.tool_selected.connect(on_tool_selected)
	#print("🎮 Player inicializado. HitComponent: ", hit_component)
	
func on_tool_selected(tool :DataTypes.Tools)-> void:
	current_tool = tool
	hit_component.current_tool = tool
	#print("🔧 Ferramenta selecionada: ", DataTypes.Tools.keys()[tool])
	
# A cada minuto que passa no relógio do jogo, o player perde vida
func _on_time_tick(_day: int, _hour: int, _minute: int) -> void:
	pass
	#adicionar_vida(-0.1) # Valor negativo faz perder vida
	#print("Relógio bateu! Vida atual: ", current_health) # <-- ADICIONE ESSA LINHA PARA TESTAR

# Função simples que adiciona vida (se positivo) ou retira vida (se negativo)
func adicionar_vida(quantidade: float) -> void:
	current_health = clampf(current_health + quantidade, 0.0, max_health)
	
	# Transmite a nova vida para o jogo inteiro ouvir!
	EventBus.player_health_changed.emit(current_health, max_health)
		
	if current_health <= 0.0:
		morrer_de_fome()
			
func morrer_de_fome() -> void:
	is_dead = true
	print("O jogador morreu de fome!")	
	
	# Emite o sinal de morte para o jogo inteiro saber
	EventBus.player_died.emit()
	
	set_physics_process(false)

## Aplica knockback ao player na direção oposta ao atacante
## @param direction: direção DE ONDE veio o ataque (ex: RIGHT = ataque veio da direita)
## @param force: força do knockback (-1 para usar knockback_force padrão)
func aplicar_knockback(direction: Vector2, force: float = -1.0) -> void:
	if is_dead:
		return
	
	var knockback_strength = force if force >= 0 else knockback_force
	
	# -direction = direção oposta (empurra para longe do atacante)
	knockback_velocity = -direction * knockback_strength
	_knockback_timer = knockback_duration

## Processa a física do knockback — roda ANTES da State Machine (pai antes dos filhos)
func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	
	if _knockback_timer > 0.0:
		velocity = knockback_velocity
		move_and_slide()
		_knockback_timer -= _delta
		# Desaceleração gradual
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_force * _delta * 2.0)
	else:
		knockback_velocity = Vector2.ZERO
