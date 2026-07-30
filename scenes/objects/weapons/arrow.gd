class_name Arrow
extends HitComponent

## Flecha disparada pela besta (Crossbow)
## Funciona como um HitComponent móvel: causa dano ao atingir um HurtComponent e se destrói

## Velocidade de deslocamento da flecha (pixels/segundo)
var speed: float = 300.0

func _ready() -> void:
	current_tool = DataTypes.Tools.Crossbow
	super._ready()
	set_as_top_level(true)

func _process(delta: float) -> void:
	position += (Vector2.RIGHT * speed).rotated(rotation) * delta

## Ao atingir um alvo com HurtComponent, causa dano (via super) e se destrói
func _on_hit_area_entered(area: Area2D) -> void:
	super._on_hit_area_entered(area)
	if area is HurtComponent:
		queue_free()

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
