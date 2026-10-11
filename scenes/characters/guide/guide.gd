extends Node2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")

## Velocidade com que o guia anda até o jogador no aviso noturno
@export var walk_speed: float = 60.0
## Distância do jogador em que o guia para
@export var stop_distance: float = 40.0
## Tempo (em segundos) de espera após a primeira conversa para lembrar de regar
@export var watering_reminder_delay: float = 60.0
## Tempo (em segundos) que o aviso flutuante de regar fica visível
@export var reminder_text_duration: float = 6.0
@export var crop_seed_tutorial_enabled: bool = true

@onready var interactable_component: InteractableComponents = $InteractableComponent
@onready var quest_indicator: Label = $QuestIndicator

var _has_talked: bool = false

# Controle do lembrete de regar (após a primeira conversa)
var _watering_reminder_active: bool = false
var _warning_label: Label
var _crop_fields: Node2D

# Controle do aviso noturno (19:00)
var _night_warning_triggered: bool = false
var _campfire_lit: bool = false
var _walking_to_player: bool = false
var _walk_target: Vector2 = Vector2.ZERO


func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interactable_activated)
	
	GameDialogueManager.give_crop_seeds.connect(on_give_crop_seeds)
	
	_animate_quest_indicator()
	_update_quest_indicator_visibility(_get_current_hour())
	_create_warning_label()
	
	# Aviso noturno: às 19h o guia vai até o jogador
	DayAndNightCycleManager.time_tick.connect(_on_time_tick)
	EventBus.campfire_lit.connect(_on_campfire_lit)


func _animate_quest_indicator() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(quest_indicator, "position:y", -46.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(quest_indicator, "position:y", -40.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _hide_quest_indicator() -> void:
	if _has_talked:
		return
	_has_talked = true
	var tween = create_tween()
	tween.tween_property(quest_indicator, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: quest_indicator.visible = false)


func on_interactable_activated() -> void:
	_start_guide_dialogue()


## Abre o diálogo automaticamente quando o player se aproxima (apenas entre 05:00 e 17:00)
func _start_guide_dialogue() -> void:
	if not crop_seed_tutorial_enabled:
		return
	# Lembrete de regar ativo: reforça o aviso em vez de reabrir a conversa inicial
	if _watering_reminder_active:
		_show_warning_label()
		return
	if _has_talked:
		return
	var hour: int = _get_current_hour()
	if hour < 5 or hour >= 17:
		return
	var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
	get_tree().root.add_child(balloon)
	balloon.start(load("res://dialogue/conversations/guide.dialogue"), "start")


## Retorna a hora atual do ciclo dia/noite (0-23)
func _get_current_hour() -> int:
	var total_minutes: int = int(DayAndNightCycleManager.time / DayAndNightCycleManager.GAME_MINUTE_DURATION)
	var day_minutes: int = total_minutes % DayAndNightCycleManager.MINUTES_PER_DAY
	@warning_ignore("integer_division")
	var hour: int = int(day_minutes / DayAndNightCycleManager.MINUTES_PER_HOUR)
	return hour


## Mostra/esconde o indicador de quest conforme a hora do dia
func _update_quest_indicator_visibility(hour: int) -> void:
	if not crop_seed_tutorial_enabled or _has_talked:
		quest_indicator.visible = false
		return
	quest_indicator.visible = hour >= 5 and hour < 17


## Enquanto o lembrete está ativo, esconde-o assim que todas as plantas forem regadas
func _process(_delta: float) -> void:
	if _watering_reminder_active and not _has_unwatered_crop():
		_watering_reminder_active = false
		_hide_reminder_indicator()


func on_give_crop_seeds() -> void:
	_hide_quest_indicator()
	ToolManager.enable_tool_button(DataTypes.Tools.PlantCorn)
	ToolManager.highlight_tool_button(DataTypes.Tools.PlantCorn)
	_start_watering_reminder_timer()


# --- LEMBRETE DE REGAR ---

## Cria o rótulo flutuante de aviso exibido acima do guia
func _create_warning_label() -> void:
	_warning_label = Label.new()
	_warning_label.name = "WateringWarning"
	_warning_label.visible = false
	_warning_label.text = "Regue as plantações!"
	_warning_label.label_settings = quest_indicator.label_settings
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_warning_label.position = Vector2(-90, -72)
	_warning_label.size = Vector2(180, 24)
	add_child(_warning_label)


## Agenda o lembrete de regar para depois de 'watering_reminder_delay' segundos
func _start_watering_reminder_timer() -> void:
	var timer := Timer.new()
	timer.name = "WateringReminderTimer"
	timer.one_shot = true
	timer.wait_time = watering_reminder_delay
	timer.timeout.connect(_on_watering_reminder_timeout)
	add_child(timer)
	timer.start()


## Disparado quando o tempo do lembrete termina: só avisa se ainda existir planta sem regar
func _on_watering_reminder_timeout() -> void:
	if _watering_reminder_active:
		return
	if not _has_unwatered_crop():
		return
	_watering_reminder_active = true
	_show_quest_indicator()
	_show_warning_label()


## Encontra (e cacheia) o container de culturas do nível
func _get_crop_fields() -> Node2D:
	if _crop_fields == null:
		_crop_fields = get_parent().find_child("CropFields") as Node2D
	return _crop_fields


## Verifica se existe alguma cultura plantada que ainda não foi regada
func _has_unwatered_crop() -> bool:
	var crop_fields := _get_crop_fields()
	if crop_fields == null:
		return false
	for child in crop_fields.get_children():
		var growth := child.get_node_or_null("GrowthCycleComponent") as GrowthCycleComponent
		if growth != null and not growth.is_watered:
			return true
	return false


## Mostra novamente o indicador de quest acima do guia
func _show_quest_indicator() -> void:
	quest_indicator.visible = true
	quest_indicator.modulate.a = 1.0


## Exibe o aviso flutuante e o esconde após alguns segundos
func _show_warning_label() -> void:
	if _warning_label == null:
		return
	_warning_label.visible = true
	_warning_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(reminder_text_duration)
	tween.tween_property(_warning_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: _warning_label.visible = false)


## Esconde o lembrete quando todas as plantas já foram regadas
func _hide_reminder_indicator() -> void:
	quest_indicator.visible = false
	if _warning_label != null:
		_warning_label.visible = false


# --- AVISO NOTURNO (19:00) ---

## Anda com o guia até o jogador enquanto o aviso noturno está ativo
func _physics_process(delta: float) -> void:
	if not _walking_to_player:
		return

	global_position = global_position.move_toward(_walk_target, walk_speed * delta)

	if global_position.distance_to(_walk_target) <= stop_distance:
		_walking_to_player = false
		_show_night_warning_dialogue()

## Escuta o relógio do jogo para disparar o aviso às 19h
func _on_time_tick(_day: int, hour: int, _minute: int) -> void:
	_update_quest_indicator_visibility(hour)
	
	if _night_warning_triggered:
		return
	# Dispara uma única vez, às 19h, se a fogueira ainda não estiver acesa
	if hour >= 19 and not _campfire_lit:
		_night_warning_triggered = true
		_start_night_warning()

func _on_campfire_lit() -> void:
	_campfire_lit = true

func _start_night_warning() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return

	# Congela o jogador até o aviso terminar
	player.freeze()

	# Anda até o jogador
	_walk_target = player.global_position
	_walking_to_player = true

func _show_night_warning_dialogue() -> void:
	var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
	get_tree().root.add_child(balloon)
	balloon.tree_exited.connect(_on_night_warning_finished)
	balloon.start(load("res://dialogue/conversations/guide_night_warning.dialogue"), "start")

func _on_night_warning_finished() -> void:
	_end_night_warning()

func _end_night_warning() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.unfreeze()
	_walking_to_player = false
	# Destaca o machado para o jogador cortar lenha
	ToolManager.enable_tool_button(DataTypes.Tools.AxeWood)
	ToolManager.highlight_tool_button(DataTypes.Tools.AxeWood)
