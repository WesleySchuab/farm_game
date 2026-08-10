class_name ActionPrompt
extends Panel

## Action Prompt - Painel de ação exibido na UI
## Escuta sinais do EventBus para mostrar/esconder com tecla e texto personalizados

@onready var key_label: Label = $Emote/ActionLabel
@onready var action_label: Label = $Emote/ActionLabel2


func _ready() -> void:
	visible = false
	
	EventBus.show_action_prompt.connect(_on_show_action_prompt)
	EventBus.hide_action_prompt.connect(_on_hide_action_prompt)


func _on_show_action_prompt(key: String, label: String) -> void:
	key_label.text = key
	action_label.text = label
	visible = true


func _on_hide_action_prompt() -> void:
	visible = false
