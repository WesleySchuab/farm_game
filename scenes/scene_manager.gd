extends Node

## ──────────────────────────────────────────────
## SceneManager — Gerencia níveis do jogo
## ──────────────────────────────────────────────
## MainScene (container persistente) carrega os
## níveis DENTRO do LevelRoot, mantendo HUD,
## Player, música e sistemas globais intactos.
##
## ⌨️ Teclas 1/2/3: pular entre níveis (dev)
## 🎮 Altere DEV_START_LEVEL abaixo.
## ──────────────────────────────────────────────

# ═══════════════════════════════════════════════
# 🎮 CONFIGURAÇÃO DE DESENVOLVIMENTO
#   0 = Level 1 (Fazenda, sem inimigos)
#   1 = Level 2 (Necromante + Mushrooms)
#   2 = Level 3 (Novo inimigo)
# ═══════════════════════════════════════════════
# Sempre um numero a menos do nome que o level leva
const DEV_START_LEVEL: int = 2

# ── Caminhos da estrutura ──
const MAIN_SCENE_PATH: String = "res://scenes/main_scene.tscn"
const MAIN_SCENE_ROOT: String = "/root/MainScene"
const LEVEL_ROOT_PATH: String = "/root/MainScene/GameRoot/LevelRoot"

# ── Lista ordenada de níveis ──
var levels: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn"
]

var level_names: Array[String] = [
	"Level 1 - Fazenda",
	"Level 2 - Necromante",
	"Level 3 - ???"
]

var current_level_index: int = DEV_START_LEVEL
var main_scene_loaded: bool = false
var debug_shortcuts_enabled: bool = true


func _ready() -> void:
	print("🗺️ [SceneManager] Inicializado. Nível inicial: ", level_names[DEV_START_LEVEL])


func _unhandled_input(event: InputEvent) -> void:
	if not debug_shortcuts_enabled:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				go_to_level(0)
			KEY_2:
				go_to_level(1)
			KEY_3:
				go_to_level(2)
			KEY_0:
				reload_current_level()
			KEY_R:
				if event.ctrl_pressed:
					reload_current_level()


# ═══════════════════════════════════════════════
# 🎯 MÉTODOS PRINCIPAIS
# ═══════════════════════════════════════════════

## Inicia o jogo: carrega a MainScene (container) UMA vez,
## depois carrega o nível inicial dentro do LevelRoot.
func start_game() -> void:
	current_level_index = DEV_START_LEVEL
	print("🗺️ [SceneManager] Iniciando jogo no ", level_names[current_level_index])
	
	if not main_scene_loaded:
		_load_main_scene()
		await _wait_for_node(LEVEL_ROOT_PATH)
	
	_load_level_into_container(current_level_index)


## Vai para um nível específico pelo índice (0, 1, 2...)
func go_to_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		print("🗺️ [SceneManager] ⚠️ Índice inválido: ", index)
		return
	
	current_level_index = index
	print("🗺️ [SceneManager] Indo para: ", level_names[current_level_index])
	
	if not main_scene_loaded:
		_load_main_scene()
		await _wait_for_node(LEVEL_ROOT_PATH)
	
	_load_level_into_container(current_level_index)


## Avança para o próximo nível
func next_level() -> void:
	go_to_level(current_level_index + 1)


## Reinicia a fase atual (recarrega o nível dentro do container)
func reload_current_level() -> void:
	print("🗺️ [SceneManager] 🔄 Reiniciando: ", level_names[current_level_index])
	_load_level_into_container(current_level_index)


## Retorna o nome do nível atual
func get_current_level_name() -> String:
	if current_level_index < level_names.size():
		return level_names[current_level_index]
	return "Desconhecido"


# ═══════════════════════════════════════════════
# 🔧 MÉTODOS INTERNOS
# ═══════════════════════════════════════════════

## Carrega a MainScene como cena principal (substitui tudo)
func _load_main_scene() -> void:
	print("🗺️ [SceneManager] Carregando MainScene (container)...")
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	main_scene_loaded = true


## Espera até que um nó exista na árvore (com timeout de 5s)
func _wait_for_node(node_path: String, timeout: float = 5.0) -> void:
	var elapsed: float = 0.0
	while not get_node_or_null(node_path) and elapsed < timeout:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	
	if not get_node_or_null(node_path):
		push_error("🗺️ [SceneManager] ❌ Timeout esperando por: ", node_path)


## Remove o nível atual do LevelRoot e carrega o novo
func _load_level_into_container(index: int) -> void:
	var level_root = get_node_or_null(LEVEL_ROOT_PATH)
	if not level_root:
		push_error("🗺️ [SceneManager] ❌ LevelRoot não encontrado em: ", LEVEL_ROOT_PATH)
		return
	
	# Remove o nível anterior
	for child in level_root.get_children():
		child.queue_free()
	
	# Espera um frame para o queue_free processar
	await get_tree().process_frame
	
	# Carrega o novo nível
	var scene_path = levels[index]
	var level_scene = load(scene_path).instantiate()
	level_root.add_child(level_scene)
	print("🗺️ [SceneManager] ✅ ", level_names[index], " carregado no LevelRoot")


# ═══════════════════════════════════════════════
# 🔧 COMPATIBILIDADE
# ═══════════════════════════════════════════════
func load_main_scene_container() -> void:
	start_game()
