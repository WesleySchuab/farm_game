class_name Campfire
extends Node2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")

## Combustível atual e máximo
@export var max_fuel: float = 100.0
@export var fuel_drain_rate: float = 2.0  # por segundo
@export var fuel_per_wood: float = 25.0   # quanto cada madeira adiciona
@export var is_lit: bool = true

var _fuel_level: float
var in_range: bool = false

@onready var interactable_component: InteractableComponents = $InteractableComponent
@onready var interact_label: Control = $InteractableLabelComponent
@onready var fire_particles: GPUParticles2D = $FireParticles
@onready var point_light: PointLight2D = $PointLight2D

func _ready() -> void:
	_fuel_level = max_fuel
	
	# Conecta aos sinais do InteractableComponent (padrão testado e funcional)
	interactable_component.interactable_activated.connect(_on_interactable_activated)
	interactable_component.interactable_deactivated.connect(_on_interactable_deactivated)
	interact_label.hide()
	
	# Conecta ao sinal de diálogo para adicionar lenha (acionado pelo .dialogue)
	GameDialogueManager.add_fuel_to_campfire.connect(_on_add_fuel_from_dialogue)
	
	# Garante que as partículas e luz comecem no estado correto
	if is_lit:
		fire_particles.emitting = true
		point_light.enabled = true
	else:
		fire_particles.emitting = false
		point_light.enabled = false

func _process(delta: float) -> void:
	if not is_lit:
		return
	# Drena combustível ao longo do tempo
	_fuel_level = max(0.0, _fuel_level - fuel_drain_rate * delta)
	_update_visuals()

	if _fuel_level <= 0.0:
		_extinguish()

func _update_visuals() -> void:
	var ratio: float = _fuel_level / max_fuel
	# Ajusta intensidade das partículas e luz
	if fire_particles.process_material is ParticleProcessMaterial:
		fire_particles.process_material.scale_min = ratio * 2.0
		fire_particles.process_material.scale_max = ratio * 4.0
	point_light.energy = ratio * 2.0
	point_light.texture_scale = ratio * 3.0

## Chamado quando o player entra na área de interação (via InteractableComponent)
func _on_interactable_activated() -> void:
	interact_label.show()
	in_range = true
	print("🔥 [CAMPFIRE] Jogador entrou no alcance da fogueira")

## Chamado quando o player sai da área de interação (via InteractableComponent)
func _on_interactable_deactivated() -> void:
	interact_label.hide()
	in_range = false
	print("🔥 [CAMPFIRE] Jogador saiu do alcance da fogueira")

## Detecta input do player para interagir com a fogueira
func _unhandled_input(event: InputEvent) -> void:
	if not in_range:
		return
	
	if event.is_action_pressed("show_dialogue"):
		interact_label.hide()
		print("🔥 [CAMPFIRE] Tecla E pressionada, abrindo diálogo...")
		
		var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
		get_tree().root.add_child(balloon)
		balloon.start(load("res://dialogue/conversations/campfire.dialogue"), "start")

## Chamado pelo diálogo via GameDialogueManager para adicionar lenha
func _on_add_fuel_from_dialogue() -> void:
	print("🔥 [CAMPFIRE] Diálogo: adicionar lenha...")
	_try_add_fuel_from_inventory()

## Tenta usar madeira do inventário para abastecer
func _try_add_fuel_from_inventory() -> void:
	var madeira: int = InventoryManager.get_inventory_count("wood")
	if madeira <= 0:
		print("🔥 [CAMPFIRE] Sem madeira no inventário!")
		return
	
	InventoryManager.remove_collectable("wood")
	_add_fuel(fuel_per_wood)
	print("🔥 [CAMPFIRE] Madeira adicionada! +", fuel_per_wood, " de combustível. Total: ", _fuel_level, "/", max_fuel)

## Adiciona combustível e reacende se necessário
func _add_fuel(amount: float) -> void:
	_fuel_level = min(max_fuel, _fuel_level + amount)
	if not is_lit and _fuel_level > 0:
		_ignite()

## Acende a fogueira
func _ignite() -> void:
	is_lit = true
	fire_particles.emitting = true
	point_light.enabled = true
	EventBus.campfire_lit.emit()
	print("🔥 [CAMPFIRE] Fogueira acesa!")

## Apaga a fogueira
func _extinguish() -> void:
	is_lit = false
	fire_particles.emitting = false
	point_light.enabled = false
	EventBus.campfire_died.emit()
	print("🔥 [CAMPFIRE] Fogueira apagou! Sem combustível.")
