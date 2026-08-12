extends Node2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")

@onready var interactable_component: InteractableComponents = $InteractableComponent
@onready var interactable_label_component: Control = $InteractableComponent/InteractableLabelComponent
@onready var quest_indicator: Label = $QuestIndicator

var in_range: bool
var _has_talked: bool = false


func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	interactable_label_component.hide()
	
	GameDialogueManager.give_crop_seeds.connect(on_give_crop_seeds)
	
	_animate_quest_indicator()


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
	ToolManager.enable_tool_button(DataTypes.Tools.TillGround)
	ToolManager.enable_tool_button(DataTypes.Tools.WaterCrops)
	ToolManager.enable_tool_button(DataTypes.Tools.PlantCorn)
	ToolManager.enable_tool_button(DataTypes.Tools.PlantTomato)
