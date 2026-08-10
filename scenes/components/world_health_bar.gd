class_name WorldHealthBar
extends ProgressBar

## Barra de vida/mundo reutilizável
## Coloque como filho de qualquer Node2D (fogueira, inimigo, etc.)
## Uso:
##   configure(bar_color, bg_color, height)  - opcional, define cores
##   setup(max_value)                        - configura valor máximo
##   update_value(current)                   - atualiza valor atual

## Cor da barra (fill)
@export var bar_color: Color = Color(0.8, 0.2, 0.2, 1.0)  # vermelho padrão

## Cor do fundo (background)
@export var bg_color: Color = Color(0.15, 0.15, 0.15, 0.8)

## Altura da barra em pixels
@export var bar_height: int = 6

## Se true, esconde automaticamente quando o valor está cheio
@export var hide_when_full: bool = true


func _ready() -> void:
	_create_styles()
	hide()


## Cria os StyleBoxFlat com as cores configuradas
func _create_styles() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color.BLACK
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_right = 2
	bg_style.corner_radius_bottom_left = 2
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_right = 2
	fill_style.corner_radius_bottom_left = 2
	
	add_theme_stylebox_override("background", bg_style)
	add_theme_stylebox_override("fill", fill_style)
	
	custom_minimum_size = Vector2(40, bar_height)


## Configura cores e altura (chame antes de setup se quiser customizar)
func configure(color: Color, background: Color = Color(0.15, 0.15, 0.15, 0.8), height: int = 6) -> void:
	bar_color = color
	bg_color = background
	bar_height = height
	_create_styles()


## Configura o valor máximo da barra e mostra
func setup(max_val: float) -> void:
	max_value = max_val
	value = max_val
	show()


## Atualiza o valor atual da barra
func update_value(current: float) -> void:
	value = current
	
	if hide_when_full and value >= max_value:
		hide()
	else:
		if value > 0 or not hide_when_full:
			show()
