extends Node2D
@onready var interactable_component: InteractableComponents = $InteractableComponent
@onready var interactable_label_component: Control = $InteractableComponent/InteractableLabelComponent

func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interectable_activated) 
	interactable_component.interactable_deactivated.connect(on_interectable_deactivated)
	interactable_label_component.hide()
	
func on_interectable_activated () -> void:
	interactable_label_component.show()
	
func on_interectable_deactivated () -> void:
	interactable_label_component.hide()
