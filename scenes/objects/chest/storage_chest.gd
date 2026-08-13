extends Node2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")

@export var storage_item: String = "corn"
@export var dialogue_start_command: String

@onready var interactable_component: Area2D = $InteractableComponent
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable_label_component: Control = $InteractableLabelComponent

var in_range: bool
var is_chest_open: bool

func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	interactable_label_component.hide()
	
	GameDialogueManager.store_item.connect(on_store_item)
	GameDialogueManager.withdraw_item.connect(on_withdraw_item)


func on_interactable_activated() -> void:
	interactable_label_component.show()
	in_range = true


func on_interactable_deactivated() -> void:
	if is_chest_open:
		animated_sprite_2d.play("chest_close")
	
	is_chest_open = false
	interactable_label_component.hide()
	in_range = false


func _unhandled_input(event: InputEvent) -> void:
	if in_range:
		if event.is_action_pressed("show_dialogue"):
			interactable_label_component.hide()
			animated_sprite_2d.play("chest_open")
			is_chest_open = true
			
			var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
			get_tree().root.add_child(balloon)
			
			var start_command = dialogue_start_command
			if _is_storage_empty():
				start_command = dialogue_start_command + "_empty"
			
			balloon.start(load("res://dialogue/conversations/storage_chest.dialogue"), start_command)


func _is_storage_empty() -> bool:
	var stored: int = InventoryManager.get_stored_amount(storage_item)
	var inventory: Dictionary = InventoryManager.inventory
	var carried: int = inventory.get(storage_item, 0)
	return stored <= 0 and carried <= 0


func on_store_item(item: String) -> void:
	if not in_range:
		return
	
	if item != storage_item:
		return
	
	var inventory: Dictionary = InventoryManager.inventory
	
	if not inventory.has(item) or inventory[item] <= 0:
		return
	
	InventoryManager.remove_collectable(item)
	InventoryManager.add_to_storage(item, 1)


func on_withdraw_item(item: String) -> void:
	if not in_range:
		return
	
	if item != storage_item:
		return
	
	var stored: int = InventoryManager.get_stored_amount(item)
	
	if stored <= 0:
		return
	
	InventoryManager.remove_from_storage(item, 1)
	InventoryManager.add_collectable(item)
