extends Node
var inventory: Dictionary = Dictionary()
signal inventory_changed

func add_collectable(collectable_name: String) -> void:
	inventory.get_or_add(collectable_name)
	
	if inventory[collectable_name] == null:
		inventory[collectable_name] = 1
		print("collectable_name == null")
	else :
		inventory[collectable_name] += 1
		print("inventory[",collectable_name,"] +=")
	inventory_changed.emit()
	
func revome_collectable(collectable_name: String) -> void:
	if inventory[collectable_name] == null:
		inventory[collectable_name] = 0
		print("collectable_name == null")
	else :
		if inventory[collectable_name] > 0:
			inventory[collectable_name] -= 1
		
	inventory_changed.emit()
