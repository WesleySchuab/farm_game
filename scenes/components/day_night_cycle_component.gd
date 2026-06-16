## Componente responsável por gerenciar visualmente o ciclo de dia e noite no jogo.
## Ele herda de CanvasModulate para tingir toda a cena 2D com as cores de um gradiente.
class_name DayNightCycleComponent
extends CanvasModulate

# --- VARIÁVEIS EXPORTADAS (CONFIGURÁVEIS NO INSPECTOR) ---

## Dia inicial em que o jogo deve começar.
@export var initial_day: int = 1:
	set(id):
		initial_day = id
		# Sincroniza o dia com o gerenciador global (Autoload)
		DayAndNightCycleManager.initial_day = id
		# Recalcula o tempo inicial com base no novo valor
		DayAndNightCycleManager.set_initial_time()

## Hora inicial em que o jogo deve começar (formato 24h).
@export var initial_hour: int = 12:
	set(ih):
		initial_hour = ih
		# Sincroniza a hora com o gerenciador global
		DayAndNightCycleManager.initial_hour = ih
		# Recalcula o tempo inicial com base no novo valor
		DayAndNightCycleManager.set_initial_time()

## Minuto inicial em que o jogo deve começar.
@export var initial_minute: int = 30:
	set(im):
		initial_minute = im
		# Sincroniza o minuto com o gerenciador global
		DayAndNightCycleManager.initial_minute = im
		# Recalcula o tempo inicial com base no novo valor
		DayAndNightCycleManager.set_initial_time()

## Textura de gradiente 1D que contém as cores do ciclo (ex: azul para noite, laranja para o por do sol).
@export var day_night_gradient_texture: GradientTexture1D


# --- FUNÇÕES DE CICLO DE VIDA DO GODOT ---

## Chamada quando o nó entra na árvore da cena pela primeira vez.
func _ready() -> void:
	# Garante que os valores configurados no Inspector sejam passados ao Gerenciador Global na inicialização
	DayAndNightCycleManager.initial_day = initial_day
	DayAndNightCycleManager.initial_hour = initial_hour
	DayAndNightCycleManager.initial_minute = initial_minute
	DayAndNightCycleManager.set_initial_time()
	
	# Conecta o sinal de passagem de tempo do Gerenciador à função local que atualiza a cor
	DayAndNightCycleManager.game_time.connect(on_game_time)


# --- FUNÇÕES CUSTOMIZADAS E CALLBACKS ---

## Função engatada ao sinal 'game_time'. É executada sempre que o tempo do jogo avança.
## @param time: O valor do tempo atual enviado pelo gerenciador (geralmente uma taxa em radianos/frames).
func on_game_time(time: float) -> void:
	# TRANSLATION MATEMÁTICA:
	# 1. sin(time - PI * 0.5) oscila o tempo em uma onda senoidal entre -1.0 e 1.0 (ajustando a fase com o PI).
	# 2. Somando 1.0, o intervalo muda para o espectro de 0.0 a 2.0.
	# 3. Multiplicando por 0.5, normalizamos o valor para ficar estritamente entre 0.0 e 1.0.
	var sample_value = 0.5 * (sin(time - PI * 0.5) + 1.0)
	
	# Pega a cor correspondente no gradiente usando o valor normalizado (0.0 = início, 1.0 = fim)
	# e aplica diretamente na propriedade 'color' do CanvasModulate para tingir a tela.
	color = day_night_gradient_texture.gradient.sample(sample_value)
