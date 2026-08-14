extends Node2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")

## Velocidade com que o guia anda até o jogador no aviso noturno
@export var walk_speed: float = 60.0
## Distância do jogador em que o guia para
@export var stop_distance: float = 40.0

@onready var interactable_component: InteractableComponents = $InteractableComponent
@onready var interactable_label_component: Control = $InteractableComponent/InteractableLabelComponent
@onready var quest_indicator: Label = $QuestIndicator

var in_range: bool
var _has_talked: bool = false

# Controle do aviso noturno (19:00)
var _night_warning_triggered: bool = false
var _campfire_lit: bool = false
var _walking_to_player: bool = false
var _walk_target: Vector2 = Vector2.ZERO


func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	interactable_label_component.hide()
	
	GameDialogueManager.give_crop_seeds.connect(on_give_crop_seeds)
	
	_animate_quest_indicator()
	
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
	tween.tween_callback(quest_indicator.queue_free)


func on_interactable_activated() -> void:
	interactable_label_component.show()
	in_range = true


func on_interactable_deactivated() -> void:
	interactable_label_component.hide()
	in_range = false


func _unhandled_input(event: InputEvent) -> void:
	if in_range:
		if event.is_action_pressed("show_dialogue"):
			_hide_quest_indicator()
			var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
			get_tree().root.add_child(balloon)
			balloon.start(load("res://dialogue/conversations/guide.dialogue"), "start")


func on_give_crop_seeds() -> void:
	ToolManager.enable_tool_button(DataTypes.Tools.PlantCorn)
	ToolManager.highlight_tool_button(DataTypes.Tools.PlantCorn)


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
