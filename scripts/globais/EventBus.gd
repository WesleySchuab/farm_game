# EventBus.gd (Configurado como Autoload/Singleton)
extends Node

# Este sinal vai avisar a qualquer um no jogo que a vida do player mudou
signal player_health_changed(current_health: float, max_health: float)

signal player_died
