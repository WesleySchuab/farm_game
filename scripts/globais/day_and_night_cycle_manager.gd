## Gerenciador Central do Ciclo de Tempo do Jogo (Geralmente configurado como Autoload/Singleton).
## Este script controla a passagem do tempo, converte frames do jogo em minutos/horas e avisa o resto do jogo quando o tempo passa.
extends Node

# --- CONSTANTES ---

## Total de minutos em um dia completo (24 horas * 60 minutos = 1440 minutos).
const MINUTES_PER_DAY: int = 24 * 60

## Quantidade de minutos em uma única hora.
const MINUTES_PER_HOUR: int = 60

## Fator de conversão do tempo. Transforma 1 minuto do jogo em radianos baseados em TAU (2 * PI ≈ 6.28318).
## Isso é usado para fazer uma rotação completa (360º ou TAU radianos) a cada ciclo de 1 dia no jogo.
const GAME_MINUTE_DURATION: float = TAU / MINUTES_PER_DAY


# --- VARIÁVEIS DE CONFIGURAÇÃO E ESTADO ---

## Velocidade do tempo no jogo. Quanto maior o número, mais rápido o dia passa (Ex: 5.0 significa que o tempo corre 5x mais rápido).
var game_speed: float = 5.0

# Variáveis que armazenam o ponto de partida do relógio (modificadas pelo componente visual no script anterior).
var initial_day: int = 1
var initial_hour: int = 12
var initial_minute: int = 30

## O relógio mestre do jogo. Um valor float contínuo acumulado em radianos que dita o momento exato do mundo.
var time: float = 0.0

## Armazena o minuto atual processado. Começa em -1 para forçar uma atualização imediata no primeiro frame.
var current_minute: int = -1

## Armazena o dia atual processado.
var current_day: int = 0


# --- SINAIS (NOTIFICAÇÕES PARA OUTROS SCRIPTS) ---

## Emitido a cada frame. Envia o valor 'time' bruto (em radianos) para shaders ou componentes visuais (como o CanvasModulate).
signal game_time(time: float)

## Emitido sempre que um minuto do jogo vira. Útil para atualizar relógios de interface (UI) ou checar eventos baseados em horários.
signal time_tick(day: int, hour: int, minute: int)

## Emitido estritamente quando o dia muda. Excelente para salvar o progresso, atualizar calendários ou recalcular rotinas diárias de NPCs.
signal time_tick_day(day: int)


# --- FUNÇÕES DE CICLO DE VIDA DO GODOT ---

## Chamada quando o gerenciador é carregado no jogo.
func _ready() -> void:
	# Define a posição inicial dos ponteiros do relógio com base nos valores iniciais fornecidos.
	set_initial_time()

## Processada a cada frame do jogo. Atualiza o relógio em tempo real.
func _process(delta: float) -> void:
	# Avança o tempo com base no tempo real decorrido (delta), na velocidade do jogo (game_speed)
	# e na escala definida para a duração do minuto (GAME_MINUTE_DURATION).
	time += delta * game_speed * GAME_MINUTE_DURATION
	
	# Envia o tempo bruto para quem estiver ouvindo (o componente visual usa isso para mudar as cores).
	game_time.emit(time)
	
	# Transforma o tempo bruto em formato legível de Dias, Horas e Minutos e emite sinais se mudarem.
	recalculate_time()


# --- FUNÇÕES CUSTOMIZADAS ---

## Converte a data/hora inicial de configuração humana em radianos brutos para a variável 'time'.
func set_initial_time() -> void:
	# Descobre quantos minutos totais se passaram desde o "dia 0" até o horário inicial configurado.
	var initial_total_minutes = initial_day * MINUTES_PER_DAY + (initial_hour * MINUTES_PER_HOUR) + initial_minute
	
	# Converte esses minutos totais para radianos.
	time = initial_total_minutes * GAME_MINUTE_DURATION

## Desmembra o valor float de 'time' de volta em inteiros legíveis de dias, horas e minutos.
func recalculate_time() -> void:
	# Descobre o total de minutos absolutos decorridos convertendo os radianos de volta.
	var total_minutes: int = int(time / GAME_MINUTE_DURATION)
	
	# Calcula em qual dia estamos dividindo os minutos totais pela quantidade de minutos que tem um dia.
	@warning_ignore("integer_division")
	var day: int = int(total_minutes / MINUTES_PER_DAY)
	
	# O resto (%) da divisão acima nos diz quantos minutos se passaram apenas dentro do dia atual.
	var current_day_minutes: int = total_minutes % MINUTES_PER_DAY
	
	# Divide os minutos do dia atual por 60 para descobrir a hora (0 a 23).
	@warning_ignore("integer_division")
	var hour: int = int(current_day_minutes / MINUTES_PER_HOUR)
	
	# O resto da divisão acima nos diz o minuto exato daquela hora (0 a 59).
	var minute: int = int(current_day_minutes % MINUTES_PER_HOUR)
	
	# GESTÃO DE SINAIS:
	# Se o minuto calculado mudou em relação ao frame anterior...
	if current_minute != minute:
		current_minute = minute
		# Avisa o jogo que o relógio bateu um novo minuto.
		time_tick.emit(day, hour, minute)
	
	# Se o dia calculado mudou em relação ao frame anterior...
	if current_day != day:
		current_day = day
		# Avisa o jogo que um novo dia nasceu.
		time_tick_day.emit(day)
