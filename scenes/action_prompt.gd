class_name ActionPrompt
extends Panel

## Action Prompt - Painel de ação exibido na UI
## Modos:
##  - texto (tecla + ação)       -> show_action_prompt
##  - animação de clique (ícone) -> show_click_animation
##  - aviso de ferramenta errada -> show_action_warning

## Texturas que alternam para formar a animação do clique
@export var click_texture_1: Texture2D = preload("res://game/assets/ui/right_clique.png")
@export var click_texture_2: Texture2D = preload("res://game/assets/ui/right_clique_2.png")
@export var click_animation_fps: float = 6.0
@export var click_icon_size: float = 36.0

@onready var key_label: Label = $Emote/ActionLabel
@onready var action_label: Label = $Emote/ActionLabel2

var _click_sprite: AnimatedSprite2D
var _warning_label: Label


func _ready() -> void:
	visible = false

	# Destaca a tecla com cor diferente para diferenciá-la do texto
	key_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))  # amarelo/dourado

	_create_click_sprite()
	_create_warning_label()

	EventBus.show_action_prompt.connect(_on_show_action_prompt)
	EventBus.hide_action_prompt.connect(_on_hide_action_prompt)
	EventBus.show_click_animation.connect(_on_show_click_animation)
	EventBus.show_action_warning.connect(_on_show_action_warning)


## Cria o ícone animado do clique, alternando entre as duas texturas
func _create_click_sprite() -> void:
	_click_sprite = AnimatedSprite2D.new()
	_click_sprite.name = "ClickSprite"
	_click_sprite.visible = false
	_click_sprite.centered = true

	var frames := SpriteFrames.new()
	frames.add_animation("click")
	frames.set_animation_loop("click", true)
	frames.set_animation_speed("click", click_animation_fps)
	frames.add_frame("click", click_texture_1)
	if click_texture_2 != null:
		frames.add_frame("click", click_texture_2)

	_click_sprite.sprite_frames = frames

	# Escala o ícone para caber na área, preservando a proporção
	if click_texture_1 != null:
		var tex_size: Vector2 = click_texture_1.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			var s: float = click_icon_size / maxf(tex_size.x, tex_size.y)
			_click_sprite.scale = Vector2(s, s)

	_click_sprite.position = Vector2(20, 25)
	add_child(_click_sprite)


## Cria o label de aviso (ferramenta errada), centralizado no painel
func _create_warning_label() -> void:
	_warning_label = Label.new()
	_warning_label.name = "WarningLabel"
	_warning_label.visible = false
	_warning_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	_warning_label.add_theme_font_size_override("font_size", 13)
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_warning_label)
	_warning_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_warning_label.offset_left = 6.0
	_warning_label.offset_right = -6.0


func _on_show_action_prompt(key: String, label: String) -> void:
	_click_sprite.visible = false
	_click_sprite.stop()
	_warning_label.visible = false
	key_label.visible = true
	action_label.visible = true
	action_label.remove_theme_color_override("font_color")
	key_label.text = key
	action_label.text = label
	visible = true


func _on_show_click_animation() -> void:
	_warning_label.visible = false
	key_label.visible = false
	action_label.visible = false
	_click_sprite.visible = true
	_click_sprite.play("click")
	visible = true


func _on_show_action_warning(label: String) -> void:
	_click_sprite.visible = false
	_click_sprite.stop()
	key_label.visible = false
	action_label.visible = false
	_warning_label.text = label
	_warning_label.visible = true
	visible = true


func _on_hide_action_prompt() -> void:
	_click_sprite.stop()
	visible = false
