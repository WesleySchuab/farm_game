extends Node2D
func _ready() -> void:
	ToolManager.enable_tool_buttoon(DataTypes.Tools.TillGround)
	ToolManager.enable_tool_buttoon(DataTypes.Tools.WaterCrops)
	ToolManager.enable_tool_buttoon(DataTypes.Tools.PlantCorn)
	ToolManager.enable_tool_buttoon(DataTypes.Tools.PlantTomato)
