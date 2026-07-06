class_name GrowthCycleComponent
extends Node

@export var current_growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Germination
@export_range(1, 365) var days_until_harvest: int = 2 

signal crop_maturity
signal crop_harvesting

var is_watered: bool
var starting_day: int = 0

func _ready() -> void:
	DayAndNightCycleManager.time_tick_day.connect(on_time_tick_day)


func on_time_tick_day(day: int) -> void:
	if is_watered:
		if starting_day == 0:
			starting_day = day
		
		# Executamos a checagem de colheita ANTES ou em conjunto para evitar confusão visual
		growth_and_harvest_logic(starting_day, day)


func growth_and_harvest_logic(starting_day: int, current_day: int) -> void:
	var total_days_passed = current_day - starting_day
	
	# 1. CORREÇÃO DA COLHEITA: Se atingiu ou passou o dia planejado, vai direto para Harvesting
	if total_days_passed >= days_until_harvest:
		if current_growth_state != DataTypes.GrowthStates.Harvesting:
			current_growth_state = DataTypes.GrowthStates.Harvesting
			crop_harvesting.emit()
		return

	# 2. LÓGICA DE CRESCIMENTO: Só roda se ainda não estiver na hora da colheita
	if current_growth_state == DataTypes.GrowthStates.Maturity:
		return
		
	var num_states = 5 
	var days_per_state = float(days_until_harvest) / float(num_states)
	
	var state_index = int(total_days_passed / days_per_state) + 1
	state_index = clampi(state_index, 1, num_states)
	
	# Força o estado a não ser "Maturity" antes da hora se os dias totais não passaram
	if state_index >= num_states and total_days_passed < days_until_harvest - 1:
		state_index = num_states - 1

	current_growth_state = state_index as DataTypes.GrowthStates
	
	if current_growth_state == DataTypes.GrowthStates.Maturity:
		crop_maturity.emit()


func get_current_growth_state() -> DataTypes.GrowthStates:
	return current_growth_state
