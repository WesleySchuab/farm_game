## Script acoplado diretamente no nó da ProgressBar (HealthBar)
extends ProgressBar

func _ready() -> void:
	# A barra se conecta ao rádio global para ouvir quando o player mudar de vida
	EventBus.player_health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(current_health: float, max_health: float) -> void:
	# A própria barra se atualiza sozinha com os dados recebidos!
	max_value = max_health
	value = current_health
