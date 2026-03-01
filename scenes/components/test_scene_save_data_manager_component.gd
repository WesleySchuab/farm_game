class_name TestSceneSaveDataManagerComponent
extends Node

func _ready() -> void:
	call_deferred("load_teste_scene")
func load_teste_scece()-> void:
	SaveGameManager.load_game()
