extends Node
signal give_crop_seed

func action_give_crop_seed()-> void:
	give_crop_seed.emit()
