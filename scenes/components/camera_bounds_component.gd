class_name CameraBoundsComponent
extends Camera2D

## ──────────────────────────────────────────────
## CameraBoundsComponent — Limites da câmera
## ──────────────────────────────────────────────
## Aplica à câmera os limites jogáveis publicados pelo
## WorldBoundsComponent via EventBus (`world_bounds_changed`).
## Assim a câmera nunca mostra a área vazia fora do mapa.
## ──────────────────────────────────────────────


func _ready() -> void:
	if not EventBus.world_bounds_changed.is_connected(_on_world_bounds_changed):
		EventBus.world_bounds_changed.connect(_on_world_bounds_changed)


func _on_world_bounds_changed(bounds: Rect2) -> void:
	limit_left = int(floor(bounds.position.x))
	limit_top = int(floor(bounds.position.y))
	limit_right = int(ceil(bounds.end.x))
	limit_bottom = int(ceil(bounds.end.y))

	print("🎥[CAMERA] Limites aplicados: ", limit_left, ", ", limit_top, " → ", limit_right, ", ", limit_bottom)
