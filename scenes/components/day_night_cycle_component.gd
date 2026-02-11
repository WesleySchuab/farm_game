class_name DayAndNightCycleComponent

extends CanvasModulate
@export var initial_day: int = 1:
	set(id):
		initial_day = id
		DayAndCycleManager.initial_day = id
		DayAndCycleManager.set_initial_time()
@export var initial_hour: int = 12:
	set(ih):
		initial_hour = ih
		DayAndCycleManager.initial_hour = ih
		DayAndCycleManager.set_initial_time()
@export var initial_minute: int = 30:
	set(im):
		initial_minute = im
		DayAndCycleManager.initial_minute = im
		DayAndCycleManager.set_initial_time()
@export var day_and_gradient_texture: GradientTexture1D

func _ready() -> void:
	DayAndCycleManager.initial_day = initial_day
	DayAndCycleManager.initial_hour = initial_hour
	DayAndCycleManager.initial_minute = initial_minute
	DayAndCycleManager.set_initial_time()
	DayAndCycleManager.game_time.connect(on_game_time)

func on_game_time(time: float)-> void:
	var sample_value = 0.5 * (sin(time- PI * 0.5) +1.0)
	color = day_and_gradient_texture.gradient.sample(sample_value)
