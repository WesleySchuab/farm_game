class_name Campfire
extends Node2D

## Combustível atual e máximo
@export var max_fuel: float = 100.0
@export var fuel_drain_rate: float = 0.2  # por segundo
@export var fuel_per_wood: float = 25.0   # quanto cada madeira adiciona
@export var is_lit: bool = true

var _fuel_level: float
var in_range: bool = false

@onready var interactable_component: InteractableComponents = $InteractableComponent
@onready var interact_label: Control = $InteractableLabelComponent
@onready var fire_particles: GPUParticles2D = $FireParticles
@onready var point_light: PointLight2D = $PointLight2D
@onready var health_bar: WorldHealthBar = $WorldHealthBar

func _ready() -> void:
	_fuel_level = max_fuel
	
	# Configura a barra de combustível (laranja/âmbar)
	health_bar.configure(Color(1.0, 0.55, 0.0), Color(0.15, 0.1, 0.05, 0.8), 5)
	health_bar.setup(max_fuel)
	health_bar.hide_when_full = true
	
	# Conecta aos sinais do InteractableComponent (padrão testado e funcional)
	interactable_component.interactable_activated.connect(_on_interactable_activated)
	interactable_component.interactable_deactivated.connect(_on_interactable_deactivated)
	interact_label.hide()
	
	# Conecta ao sinal de inventário para atualizar prompt quando madeira mudar
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	
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
	health_bar.update_value(_fuel_level)

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
	in_range = true
	print("🔥 [CAMPFIRE] Jogador entrou no alcance da fogueira")
	_update_action_prompt()

## Chamado quando o player sai da área de interação (via InteractableComponent)
func _on_interactable_deactivated() -> void:
	in_range = false
	print("🔥 [CAMPFIRE] Jogador saiu do alcance da fogueira")
	_hide_action_prompt()

## Atualiza o Action Prompt baseado na proximidade e madeira disponível
func _update_action_prompt() -> void:
	if not in_range:
		return
	
	var madeira: int = InventoryManager.get_inventory_count("wood")
	if madeira > 0:
		EventBus.show_action_prompt.emit("I", "Abastecer")
	else:
		_hide_action_prompt()

## Esconde o Action Prompt
func _hide_action_prompt() -> void:
	EventBus.hide_action_prompt.emit()

## Callback quando o inventário muda (para atualizar prompt em tempo real)
func _on_inventory_changed() -> void:
	if in_range:
		_update_action_prompt()

## Detecta input do player para abastecer a fogueira via Action Prompt
func _unhandled_input(event: InputEvent) -> void:
	if not in_range:
		return
	
	if event.is_action_pressed("interact"):
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
	
	# Atualiza o prompt (some se acabou a madeira)
	_update_action_prompt()

## Adiciona combustível e reacende se necessário
func _add_fuel(amount: float) -> void:
	_fuel_level = min(max_fuel, _fuel_level + amount)
	health_bar.update_value(_fuel_level)
	if not is_lit and _fuel_level > 0:
		_ignite()

## Acende a fogueira
func _ignite() -> void:
	is_lit = true
	fire_particles.emitting = true
	point_light.enabled = true
	health_bar.show()
	EventBus.campfire_lit.emit()
	print("🔥 [CAMPFIRE] Fogueira acesa!")

## Apaga a fogueira
func _extinguish() -> void:
	is_lit = false
	fire_particles.emitting = false
	point_light.enabled = false
	health_bar.hide()
	EventBus.campfire_died.emit()
	print("🔥 [CAMPFIRE] Fogueira apagou! Sem combustível.")
