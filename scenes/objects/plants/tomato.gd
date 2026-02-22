extends Node2D
var tomato_harvest_scene = preload("res://scenes/objects/plants/tomato_harvest.tscn")

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var watering_particles: GPUParticles2D = $WateringParticles
@onready var floring_particles: GPUParticles2D = $FloringParticles
@onready var growth_cycle_component: GrowthCycleComponent = $GrowthCycleComponent
@onready var hurt_component: HurtComponent = $HurtComponent

var growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Germination
var previous_frame: int = 0

# Mapeamento dos estados para frames do sprite
# Frame 0 = bolsa (harvest), Frame 1 = semente inicial
var growth_frames = {
	DataTypes.GrowthStates.Germination: 7,
	DataTypes.GrowthStates.Seed: 8,
	DataTypes.GrowthStates.Vegetative: 9,
	DataTypes.GrowthStates.Reproduction: 10,
	DataTypes.GrowthStates.Maturity: 11,
	#DataTypes.GrowthStates.Harvesting: 6
}

func _get_frame_for_state(state: DataTypes.GrowthStates) -> int:
	if growth_frames.has(state):
		return growth_frames[state]
	return growth_frames[DataTypes.GrowthStates.Maturity]

func _ready() -> void:
	watering_particles.emitting = false
	floring_particles.emitting = false
	
	print(" tomato ANTES - sprite_2d.frame: ", sprite_2d.frame, " | hframes: ", sprite_2d.hframes, " | vframes: ", sprite_2d.vframes)
	print("tomato ANTES - texture: ", sprite_2d.texture)
	print("tomato ANTES - growth_cycle_component estado: ", DataTypes.GrowthStates.keys()[growth_cycle_component.get_current_growth_state()])
	
	# Forçar frame inicial correto
	growth_state = growth_cycle_component.get_current_growth_state()
	var target_frame = _get_frame_for_state(growth_state)
	sprite_2d.frame = target_frame
	previous_frame = sprite_2d.frame
	
	print("tomato DEPOIS - sprite_2d.frame: ", sprite_2d.frame, " (esperado: ", target_frame, ")")
	print("tomato Mapeamento usado: estado ", DataTypes.GrowthStates.keys()[growth_state], " (", growth_state, ") -> frame ", target_frame)
	print("tomato Frames disponíveis: ", growth_frames)
	
	# Verificar se frame foi aplicado corretamente
	await get_tree().process_frame
	print("tomato VERIFICAÇÃO após process_frame - sprite_2d.frame: ", sprite_2d.frame)
	
	hurt_component.hurt.connect(on_hurt)
	growth_cycle_component.crop_maturity.connect(on_crop_maturiry)
	growth_cycle_component.crop_harvesting.connect(on_crop_harvesting)

func _process(delta: float) -> void:
	growth_state = growth_cycle_component.get_current_growth_state()
	#sprite_2d.frame = growth_state + start_tomato_frame_offset
	var expected_frame = _get_frame_for_state(growth_state)
	
	# Debug se o frame está incorreto
	if sprite_2d.frame != expected_frame:
		print("⚠️ ERRO! Frame incorreto: ", sprite_2d.frame, " | Esperado: ", expected_frame, " | Estado: ", DataTypes.GrowthStates.keys()[growth_state])
		sprite_2d.frame = expected_frame
	
	# Debug quando o frame mudar
	if sprite_2d.frame != previous_frame:
		print("tomato Frame mudou! Novo frame: ", sprite_2d.frame, " | Estado: ", DataTypes.GrowthStates.keys()[growth_state])
		previous_frame = sprite_2d.frame
	
	if growth_state == DataTypes.GrowthStates.Maturity:
		floring_particles.emitting = true

func on_hurt(hit_damage: int )-> void:
	print("tomato  on_hurt chamado! Dano: ", hit_damage, " | Já regado: ", growth_cycle_component.is_watered)
	if !growth_cycle_component.is_watered:
		print("💧 Iniciando processo de regar...")
		watering_particles.emitting = true
		await get_tree().create_timer(5.0).timeout
		growth_cycle_component.is_watered = true
		print("tomato is_watered definido como TRUE imediatamente!")
		await get_tree().create_timer(5.0).timeout
		watering_particles.emitting = false
		print("💧 Partículas de água desligadas")
	else:
		print("⚠️ Planta já está regada!")
func on_crop_maturiry() -> void:
	floring_particles.emitting = true

func on_crop_harvesting() -> void:
	var tomato_harvest_instance = tomato_harvest_scene.instantiate() as Node2D
	tomato_harvest_instance.global_position = global_position
	get_parent().add_child(tomato_harvest_instance)
	queue_free()
