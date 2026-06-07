extends Node
signal give_crop_seed
signal feed_the_animals

func action_give_crop_seed()-> void:
	give_crop_seed.emit()

func action_feed_animals()-> void:
	feed_the_animals.emit()
