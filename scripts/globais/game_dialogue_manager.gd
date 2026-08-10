extends Node

signal give_crop_seeds
signal feed_the_animals
signal store_item(item: String)
signal withdraw_item(item: String)
signal add_fuel_to_campfire


func action_give_crop_seed() -> void:
	give_crop_seeds.emit()

func action_feed_animals() -> void:
	feed_the_animals.emit()

func action_store_item(item: String) -> void:
	store_item.emit(item)

func action_withdraw_item(item: String) -> void:
	withdraw_item.emit(item)

func action_add_fuel_to_campfire() -> void:
	add_fuel_to_campfire.emit()
