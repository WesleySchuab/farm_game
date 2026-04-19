extends Node2D
var balloon_scene  = preload("res://dialogue/game_dialogue_balloon.tscn")
@onready var interactable_component: InteractableComponents = $InteractableComponent
@onready var interactable_label_component: Control = $InteractableComponent/InteractableLabelComponent
var in_range: bool
func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interectable_activated) 
	interactable_component.interactable_deactivated.connect(on_interectable_deactivated)
	interactable_label_component.hide()
	
func on_interectable_activated () -> void:
	interactable_label_component.show()
	in_range = true
	
func on_interectable_deactivated () -> void:
	interactable_label_component.hide()
	in_range = false
	
func _unhandled_input(event: InputEvent) -> void:
	if in_range:
		if event.is_action_pressed("show_dialogue"):
			var dialogue_resource = load("res://dialogue/conversations/guide.dialogue")
			if dialogue_resource == null:
				printerr("❌ Erro: Não foi possível carregar o arquivo de diálogo. Verifique se guide.dialogue existe e está compilado corretamente.")
				return
			var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
			get_tree().current_scene.add_child(balloon)
			balloon.start(dialogue_resource, "start")
