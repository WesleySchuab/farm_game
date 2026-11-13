extends CharacterBody2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")

## Velocidade com que o guia se aproxima quando a fogueira está apagada
@export var walk_speed: float = 60.0
## Distância do jogador em que o guia para
@export var stop_distance: float = 40.0
## Distância usada para detectar obstáculos durante a aproximação
@export var obstacle_lookahead: float = 48.0
## Tempo (em segundos) de espera após a primeira conversa para lembrar de regar
@export var watering_reminder_delay: float = 60.0
## Tempo (em segundos) que o aviso flutuante de regar fica visível
@export var reminder_text_duration: float = 6.0
@export var crop_seed_tutorial_enabled: bool = true
@export var campfire_warning_enabled: bool = true

const APPROACH_DELAY_GAME_MINUTES: float = 2.0

@onready var interactable_component: InteractableComponents = $InteractableComponent
@onready var quest_indicator: Label = $QuestIndicator
@onready var character_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _has_talked: bool = false

# Marca que o indicador de quest já foi dispensado (o diálogo já começou)
var _indicator_dismissed: bool = false

# Controle do lembrete de regar (após a primeira conversa)
var _watering_reminder_active: bool = false
var _warning_label: Label
var _crop_fields: Node2D
var _active_dialogue: BaseGameDialogueBalloon

# Controle do aviso de anoitecer
var _approach_timer_elapsed: bool = false
var _approach_started: bool = false
var _campfire_warning_finished: bool = false
var _game_time_at_start: float = 0.0
var _home_position: Vector2 = Vector2.ZERO
var _campfire_lit: bool = false
var _walking_to_player: bool = false
var _returning_to_start: bool = false
var _walk_target: Vector2 = Vector2.ZERO
## Direção visual atual do guia: front, back, left ou right
var _facing: String = "front"


func _ready() -> void:
	if not crop_seed_tutorial_enabled and not campfire_warning_enabled:
		quest_indicator.hide()
		$BodyCollision.set_deferred("disabled", true)
		$InteractableComponent/CollisionShape2D.set_deferred("disabled", true)
		call_deferred("_unfreeze_level_player")
		print("👹[GUIDE] Procedimentos desativados neste nível")
		return

	interactable_component.interactable_activated.connect(on_interactable_activated)
	
	GameDialogueManager.give_crop_seeds.connect(on_give_crop_seeds)
	
	_animate_quest_indicator()
	_update_quest_indicator_visibility(_get_current_hour())
	_create_warning_label()
	
	_game_time_at_start = DayAndNightCycleManager.time
	_home_position = global_position
	if crop_seed_tutorial_enabled:
		DayAndNightCycleManager.time_tick.connect(_on_time_tick)
	if campfire_warning_enabled:
		EventBus.campfire_lit.connect(_on_campfire_lit)


func _unfreeze_level_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.unfreeze()


func _animate_quest_indicator() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(quest_indicator, "position:y", -46.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(quest_indicator, "position:y", -40.0, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _hide_quest_indicator() -> void:
	if _has_talked:
		return
	_has_talked = true
	_hide_quest_indicator_visual()


## Esconde o indicador de quest (com fade) sem alterar o estado da conversa
func _hide_quest_indicator_visual() -> void:
	if not quest_indicator.visible:
		return
	var tween = create_tween()
	tween.tween_property(quest_indicator, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: quest_indicator.visible = false)


func on_interactable_activated() -> void:
	_start_guide_dialogue()


## Abre o diálogo automaticamente quando o player se aproxima (apenas entre 05:00 e 17:00)
func _start_guide_dialogue() -> void:
	if not crop_seed_tutorial_enabled:
		return
	if not _campfire_warning_finished or _walking_to_player or _has_active_dialogue():
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
	_active_dialogue = balloon
	get_tree().root.add_child(balloon)
	balloon.tree_exited.connect(_on_guide_dialogue_finished)
	balloon.start(load("res://dialogue/conversations/guide.dialogue"), "start")
	# O indicador de quest só some depois que o diálogo começa
	_indicator_dismissed = true
	_hide_quest_indicator_visual()


func _has_active_dialogue() -> bool:
	return is_instance_valid(_active_dialogue)


func _on_guide_dialogue_finished() -> void:
	_active_dialogue = null
	_try_start_approach()


## Retorna a hora atual do ciclo dia/noite (0-23)
func _get_current_hour() -> int:
	var total_minutes: int = int(DayAndNightCycleManager.time / DayAndNightCycleManager.GAME_MINUTE_DURATION)
	var day_minutes: int = total_minutes % DayAndNightCycleManager.MINUTES_PER_DAY
	@warning_ignore("integer_division")
	var hour: int = int(day_minutes / DayAndNightCycleManager.MINUTES_PER_HOUR)
	return hour


## Mostra/esconde o indicador de quest conforme a hora do dia
func _update_quest_indicator_visibility(hour: int) -> void:
	if (
		not crop_seed_tutorial_enabled
		or not _campfire_warning_finished
		or _has_talked
		or _indicator_dismissed
	):
		quest_indicator.visible = false
		return
	quest_indicator.visible = hour >= 5 and hour < 17


func _on_time_tick(_day: int, hour: int, _minute: int) -> void:
	_update_quest_indicator_visibility(hour)


## Enquanto o lembrete está ativo, esconde-o assim que todas as plantas forem regadas
func _process(_delta: float) -> void:
	if campfire_warning_enabled and not _approach_timer_elapsed:
		var elapsed_game_time: float = DayAndNightCycleManager.time - _game_time_at_start
		var required_game_time: float = (
			APPROACH_DELAY_GAME_MINUTES * DayAndNightCycleManager.GAME_MINUTE_DURATION
		)
		if elapsed_game_time >= required_game_time:
			_approach_timer_elapsed = true
			if _campfire_lit:
				_unlock_crop_dialogue()
			else:
				_try_start_approach()

	if _watering_reminder_active and not _has_unwatered_crop():
		_watering_reminder_active = false
		_hide_reminder_indicator()


func on_give_crop_seeds() -> void:
	_hide_quest_indicator()
	ToolManager.enable_tool_button(DataTypes.Tools.PlantCorn)
	ToolManager.enable_tool_button(DataTypes.Tools.WaterCrops)
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
	# Após avisar para regar, destaca a ferramenta de regar (regador)
	ToolManager.highlight_tool_button(DataTypes.Tools.WaterCrops)


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


# --- AVISO DE ANOITECER ---

## Anda com o guia até o jogador enquanto o aviso está ativo
func _physics_process(delta: float) -> void:
	if not _walking_to_player and not _returning_to_start:
		return

	var target_position := _home_position if _returning_to_start else _walk_target
	var distance_to_target := global_position.distance_to(target_position)
	var arrival_distance := 2.0 if _returning_to_start else stop_distance
	if distance_to_target <= arrival_distance:
		velocity = Vector2.ZERO
		_play_animation("idle_" + _facing)
		if _returning_to_start:
			global_position = _home_position
			_returning_to_start = false
			_unlock_crop_dialogue()
		else:
			_walking_to_player = false
			_show_night_warning_dialogue()
		return

	var direction := global_position.direction_to(target_position)
	direction = _get_avoiding_direction(direction)
	velocity = direction * walk_speed
	move_and_slide()
	_update_walking_animation(velocity)


## Escolhe a animação de caminhada/parado conforme a direção do movimento
func _update_walking_animation(movement: Vector2) -> void:
	if movement == Vector2.ZERO:
		_play_animation("idle_" + _facing)
		return
	_facing = _get_facing_from_direction(movement)
	_play_animation("walk_" + _facing)


## Converte um vetor de movimento na direção visual dominante
func _get_facing_from_direction(direction: Vector2) -> String:
	if absf(direction.x) >= absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "front" if direction.y > 0.0 else "back"


## Toca a animação apenas se ela ainda não estiver tocando
func _play_animation(animation_name: String) -> void:
	if character_sprite.animation != animation_name:
		character_sprite.play(animation_name)


func _get_avoiding_direction(direction: Vector2) -> Vector2:
	var space_state := get_world_2d().direct_space_state
	if not _is_direction_blocked(space_state, direction):
		return direction

	var best_direction := Vector2.ZERO
	var best_score := -INF
	for angle in [-PI / 3.0, -PI / 6.0, PI / 6.0, PI / 3.0, -PI / 2.0, PI / 2.0]:
		var candidate := direction.rotated(angle).normalized()
		var query := PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + candidate * obstacle_lookahead
		)
		query.collision_mask = 1
		query.exclude = [get_rid()]
		var hit := space_state.intersect_ray(query)
		var clearance := obstacle_lookahead
		if not hit.is_empty():
			clearance = global_position.distance_to(hit.position)
		var score := direction.dot(candidate) * 0.35 + clearance / obstacle_lookahead * 0.65
		if score > best_score:
			best_score = score
			best_direction = candidate

	return best_direction


func _is_direction_blocked(space_state: PhysicsDirectSpaceState2D, direction: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * obstacle_lookahead
	)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return not space_state.intersect_ray(query).is_empty()


func _on_campfire_lit() -> void:
	_campfire_lit = true
	if _approach_timer_elapsed and not _approach_started:
		_unlock_crop_dialogue()


func _unlock_crop_dialogue() -> void:
	_campfire_warning_finished = true
	_update_quest_indicator_visibility(_get_current_hour())


func _try_start_approach() -> void:
	if (
		not campfire_warning_enabled
		or not _approach_timer_elapsed
		or _campfire_lit
		or _approach_started
		or _has_active_dialogue()
	):
		return

	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player == null:
		push_warning("👹[GUIDE] O jogador não foi encontrado para iniciar a aproximação")
		return

	_approach_started = true
	player.freeze()
	_walk_target = player.global_position
	_walking_to_player = true
	AudioManager.play_music(AudioManager.MUSIC.FIRE_ON)
	print("👹[GUIDE] Aviso de anoitecer iniciado")


func _show_night_warning_dialogue() -> void:
	var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
	_active_dialogue = balloon
	get_tree().root.add_child(balloon)
	balloon.tree_exited.connect(_on_night_warning_finished)
	balloon.start(load("res://dialogue/conversations/guide_night_warning.dialogue"), "start")


func _on_night_warning_finished() -> void:
	_end_night_warning()


func _end_night_warning() -> void:
	_walking_to_player = false
	_active_dialogue = null
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.unfreeze()
	AudioManager.play_music(AudioManager.MUSIC.ON_THE_FARM)
	_returning_to_start = true
	# Destaca o machado para o jogador cortar lenha
	ToolManager.enable_tool_button(DataTypes.Tools.AxeWood)
	ToolManager.highlight_tool_button(DataTypes.Tools.AxeWood)
