class_name PlayerHurtComponent
extends Area2D

## Componente de dano para o player
## Detecta quando o inimigo ataca e aplica dano

## Referência ao player
@onready var player: Player = get_parent()

## Sinal emitido quando recebe dano
signal hurt(damage: int)


func _ready() -> void:
	monitoring = true
	monitorable = true
	print("🛡️ [PLAYER HURT] PlayerHurtComponent pronto")
	
	# Conecta ao sinal de entrada de área
	area_entered.connect(_on_area_entered)


## Callback quando uma área entra em colisão
func _on_area_entered(area: Area2D) -> void:
	print("🛡️ [PLAYER HURT] Detectada colisão com: ", area.name)
	
	var hit_component = area as HitComponent
	if hit_component == null:
		print("❌ [PLAYER HURT] Área não é um HitComponent")
		return
	
	print("✅ [PLAYER HURT] HitComponent detectado! Dano: ", hit_component.hit_damage)
	
	# Aplica dano ao player
	if player:
		player.adicionar_vida(-hit_component.hit_damage)
		hurt.emit(hit_component.hit_damage)
		print("💥 [PLAYER HURT] Player recebeu ", hit_component.hit_damage, " de dano! Vida: ", player.current_health)
