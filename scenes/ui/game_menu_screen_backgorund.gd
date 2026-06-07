extends Node2D

func _ready() -> void:
	call_deferred("set_escenes_process_mode")

func set_escenes_process_mode() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
