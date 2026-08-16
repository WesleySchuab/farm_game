extends PanelContainer
@onready var tool_axe: Button = $MarginContainer/HBoxContainer/ToolAxe
@onready var tool_tilling: Button = $MarginContainer/HBoxContainer/ToolTilling
@onready var tool_watering_can: Button = $MarginContainer/HBoxContainer/ToolWateringCan
@onready var tool_corn: Button = $MarginContainer/HBoxContainer/ToolCorn
@onready var tool_tomato: Button = $MarginContainer/HBoxContainer/ToolTomato
@onready var tool_rock: Button = $MarginContainer/HBoxContainer/ToolRock

func _ready() -> void:
	ToolManager.enable_tool.connect(on_enable_tool_button)
	ToolManager.highlight_tool.connect(on_highlight_tool_button)
	
	tool_tilling.disabled = false
	tool_tilling.focus_mode = Control.FOCUS_NONE
	
	tool_watering_can.disabled = false
	#tool_watering_can.focus_mode = Control.FOCUS_NONE
	
	tool_corn.disabled = true
	tool_corn.focus_mode = Control.FOCUS_NONE
	
	tool_tomato.disabled = true
	tool_tomato.focus_mode = Control.FOCUS_NONE

#func _on_tool_axe_pressed() -> void:
	#ToolManager.select_tool(DataTypes.Tools.AxeWood)


func _on_tool_tilling_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.TillGround)


func _on_tool_watering_can_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.WaterCrops)


func _on_tool_corn_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.PlantCorn)


func _on_tool_tomato_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.PlantTomato)


func _on_cross_bow_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.Crossbow)
#Não funcionou	
#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_RIGHT:
			#ToolManager.select_tool(DataTypes.Tools.None)
			#tool_axe.release_focus()
			#tool_tilling.release_focus()
			#tool_watering_can.release_focus()
			#tool_corn.release_focus()
			#tool_tomato.release_focus()
func on_enable_tool_button(tool:DataTypes.Tools) -> void:
	if tool == DataTypes.Tools.TillGround:
		tool_tilling.disabled = false
		tool_tilling.focus_mode = Control.FOCUS_ALL
	elif tool == DataTypes.Tools.WaterCrops:
		tool_watering_can.disabled = false
		tool_watering_can.focus_mode = Control.FOCUS_ALL
	elif tool == DataTypes.Tools.PlantCorn:
		tool_corn.disabled = false
		tool_corn.focus_mode = Control.FOCUS_ALL
	elif tool == DataTypes.Tools.PlantTomato:
		tool_tomato.disabled = false
		tool_tomato.focus_mode = Control.FOCUS_ALL
	elif tool == DataTypes.Tools.AxeWood:
		tool_axe.disabled = false
		tool_axe.focus_mode = Control.FOCUS_ALL
	elif tool == DataTypes.Tools.BuildRock:
		tool_rock.disabled = false
		tool_rock.focus_mode = Control.FOCUS_ALL


func on_highlight_tool_button(tool: DataTypes.Tools) -> void:
	var button: Button = _get_tool_button(tool)
	if button == null:
		return
	ToolManager.select_tool(tool)
	button.grab_focus()
	_pulse_highlight(button)


func _get_tool_button(tool: DataTypes.Tools) -> Button:
	match tool:
		DataTypes.Tools.TillGround:
			return tool_tilling
		DataTypes.Tools.WaterCrops:
			return tool_watering_can
		DataTypes.Tools.PlantCorn:
			return tool_corn
		DataTypes.Tools.PlantTomato:
			return tool_tomato
		DataTypes.Tools.AxeWood:
			return tool_axe
		DataTypes.Tools.BuildRock:
			return tool_rock
		_:
			return null


func _pulse_highlight(button: Button) -> void:
	button.pivot_offset = button.size / 2.0
	var original_scale: Vector2 = button.scale
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(button, "scale", original_scale * 1.2, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", original_scale, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_tool_axe_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.AxeWood)


func _on_tool_rock_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.BuildRock)
