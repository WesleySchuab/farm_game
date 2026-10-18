class_name WorldBoundsComponent
extends Node

## ──────────────────────────────────────────────
## WorldBoundsComponent — Limites jogáveis do nível
## ──────────────────────────────────────────────
## Calcula a área jogável do nível atual a partir das camadas
## de TileMapLayer (por padrão a camada "Grass") e:
##   1. publica os limites no EventBus (`world_bounds_changed`);
##   2. impede o player de sair dessa área.
##
## Assim a câmera e o player ficam sempre dentro do mapa,
## independentemente do tamanho da tela.
## ──────────────────────────────────────────────

## Camadas usadas como referência para o limite.
## Vazio = usa a união de TODAS as TileMapLayer do nível.
@export var boundary_layer_names: PackedStringArray = PackedStringArray(["Grass"])

## Margem (px) entre o centro do player e a borda do mapa.
@export var edge_margin: float = 16.0

## Se false, apenas publica os limites (não limita o player).
@export var clamp_player: bool = true

## Área jogável atual (coordenadas globais do mundo).
var bounds: Rect2 = Rect2()

## True quando já existe um limite calculado para o nível atual.
var has_bounds: bool = false

## Referência em cache ao jogador (persiste entre níveis)
var _player: Node2D = null


func _ready() -> void:
	# Garante que o clamp rode DEPOIS do movimento do player
	process_physics_priority = 100

	if not SceneManager.level_loaded.is_connected(_on_level_loaded):
		SceneManager.level_loaded.connect(_on_level_loaded)

	# Caso o nível já esteja carregado (recarregar o MainScene)
	call_deferred("_refresh_bounds")


func _on_level_loaded(_index: int, _level: Node) -> void:
	call_deferred("_refresh_bounds")


## Recalcula os limites a partir das camadas do nível atual
func _refresh_bounds() -> void:
	# Espera um frame para o nível novo estar pronto na árvore
	await get_tree().process_frame

	has_bounds = false

	var level_root := get_node_or_null(SceneManager.LEVEL_ROOT_PATH)
	if level_root == null:
		return

	var layers := level_root.find_children("*", "TileMapLayer", true, false)
	if layers.is_empty():
		print("🧱[BOUNDS] ⚠️ Nenhuma TileMapLayer encontrada no nível.")
		return

	var result := Rect2()
	var found := false

	for node in layers:
		var layer := node as TileMapLayer
		if layer == null or layer.tile_set == null:
			continue

		# Filtra pelas camadas de referência (quando configuradas)
		if not boundary_layer_names.is_empty() and not boundary_layer_names.has(String(layer.name)):
			continue

		var used := layer.get_used_rect()
		if used.size.x <= 0 or used.size.y <= 0:
			continue

		var tile_size := Vector2(layer.tile_set.tile_size)
		var local_rect := Rect2(Vector2(used.position) * tile_size, Vector2(used.size) * tile_size)
		var world_rect: Rect2 = layer.global_transform * local_rect

		result = world_rect if not found else result.merge(world_rect)
		found = true

	if not found:
		print("🧱[BOUNDS] ⚠️ Camadas configuradas não encontradas: ", boundary_layer_names)
		return

	bounds = result
	has_bounds = true

	print("🧱[BOUNDS] Área jogável: x %.0f..%.0f | y %.0f..%.0f" % [
		bounds.position.x, bounds.end.x, bounds.position.y, bounds.end.y
	])

	EventBus.world_bounds_changed.emit(bounds)


## Mantém o player dentro da área jogável
func _physics_process(_delta: float) -> void:
	if not clamp_player or not has_bounds:
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		return

	var min_pos := bounds.position + Vector2(edge_margin, edge_margin)
	var max_pos := bounds.end - Vector2(edge_margin, edge_margin)

	# Evita limites invertidos em mapas menores que a margem
	max_pos = Vector2(maxf(min_pos.x, max_pos.x), maxf(min_pos.y, max_pos.y))

	_player.global_position = _player.global_position.clamp(min_pos, max_pos)
