## Classe principal do jogador
## Gerencia o personagem controlável do jogo
class_name Player
extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D
@onready var hit_component: HitComponent = $HitComponent

@export var max_health: float = 100.0
var current_health: float = 100.0

## Armazena a direção que o jogador está olhando (UP, DOWN, LEFT, RIGHT)
var player_direction: Vector2

## Ferramenta atualmente equipada pelo jogador
@export var current_tool: DataTypes.Tools = DataTypes.Tools.None

# Variável de controle para o player não ficar morrendo de fome em loop a cada frame
var is_dead: bool = false

func _ready() -> void:
	# Avisa o EventBus logo no início para a barra começar cheia
	# Usamos 'callable.call_deferred' para garantir que a barra já exista na tela antes de enviar o valor
	EventBus.player_health_changed.emit.call_deferred(current_health, max_health)
	current_health = max_health
	
		
	# Conecta ao gerenciador de tempo para a vida descer com o passar das horas
	if DayAndNightCycleManager:
		DayAndNightCycleManager.time_tick.connect(_on_time_tick)
		
	ToolManager.tool_selected.connect(on_tool_selected)
	print("🎮 Player inicializado. HitComponent: ", hit_component)
	
func on_tool_selected(tool :DataTypes.Tools)-> void:
	current_tool = tool
	hit_component.current_tool = tool
	print("🔧 Ferramenta selecionada: ", DataTypes.Tools.keys()[tool])
	
# A cada minuto que passa no relógio do jogo, o player perde vida
func _on_time_tick(_day: int, _hour: int, _minute: int) -> void:
	#adicionar_vida(-0.1) # Valor negativo faz perder vida
	print("Relógio bateu! Vida atual: ", current_health) # <-- ADICIONE ESSA LINHA PARA TESTAR

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
