extends Node

var inventory: Dictionary = Dictionary()
var storage: Dictionary = Dictionary()

signal inventory_changed
signal storage_changed

func add_collectable(collectable_name: String) -> void:
	inventory.get_or_add(collectable_name)
	
	if inventory[collectable_name] == null:
		inventory[collectable_name] = 1
	else:
		inventory[collectable_name] += 1
	
	inventory_changed.emit()


func remove_collectable(collectable_name: String) -> void:
	if inventory[collectable_name] == null:
		inventory[collectable_name] = 0
	else:
		if inventory[collectable_name] > 0:
			inventory[collectable_name] -= 1
	
	inventory_changed.emit()


func add_to_storage(item: String, amount: int) -> void:
	storage.get_or_add(item)
	
	if storage[item] == null:
		storage[item] = amount
	else:
		storage[item] += amount
	
	storage_changed.emit()


func remove_from_storage(item: String, amount: int) -> void:
	if not storage.has(item) or storage[item] == null:
		return
	
	storage[item] = max(0, storage[item] - amount)
	storage_changed.emit()


func get_stored_amount(item: String) -> int:
	if not storage.has(item) or storage[item] == null:
		return 0
	return storage[item]


func get_inventory_count(item: String) -> int:
	if not inventory.has(item) or inventory[item] == null:
		return 0
	return inventory[item]
