class_name  GrowthCycleComponent
extends Node

@export var current_growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Germination
@export_range(5, 36) var day_until_harvest: int =7

signal crop_maturity
signal crop_harvesting

var _is_watered: bool = false
var is_watered: bool:
	set(value):
		_is_watered = value
		print("🚰 is_watered mudou para: ", value)
	get:
		return _is_watered
		
var starting_day: int
var current_day: int

func _ready() -> void:
	print("🌱 GrowthCycleComponent _ready - Estado inicial: ", DataTypes.GrowthStates.keys()[current_growth_state], " (", current_growth_state, ")")
	DayAndCycleManager.time_tick_day.connect(on_time_tick_day)
	
func on_time_tick_day(day: int) -> void:
	print("📅 Day tick: ", day, " | Regado: ", is_watered, " | Starting day: ", starting_day)
	if is_watered:
		if starting_day == 0:
			starting_day = day
			print("🌱 Iniciando crescimento no dia: ", day)
		growth_states(starting_day, day)
		harvest_state(starting_day, day)
		
func growth_states(starting_day: int, current_day: int):
	if current_growth_state == DataTypes.GrowthStates.Maturity:
		return
	var num_states = 5
	var growth_days_passed =(current_day - starting_day) % num_states
	var state_index = growth_days_passed % num_states
	
	current_growth_state = state_index
	
	var name = DataTypes.GrowthStates.keys()[current_growth_state]
	print("🌱 Growth State: ", name, " | State Index: ", state_index, " | Days: ", growth_days_passed)
	
	if current_growth_state == DataTypes.GrowthStates.Maturity:
		crop_maturity.emit()
func harvest_state(starting_day: int, current_day: int):
	if current_growth_state == DataTypes.GrowthStates.Harvesting:
		return
	var days_passed = (current_day - starting_day) % day_until_harvest
	if days_passed == day_until_harvest:
		current_growth_state = DataTypes.GrowthStates.Harvesting
		crop_harvesting.emit()
func get_current_growth_state() -> DataTypes.GrowthStates:
	return current_growth_state
