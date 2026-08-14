# EventBus.gd (Configurado como Autoload/Singleton)
extends Node

# Este sinal vai avisar a qualquer um no jogo que a vida do player mudou
signal player_health_changed(current_health: float, max_health: float)

signal player_died

signal campfire_lit
signal campfire_died
signal campfire_fuel_changed(fuel: float, max_fuel: float)

## Sinais para controlar o Action Prompt (UI)
signal show_action_prompt(key: String, label: String)
signal hide_action_prompt

## Mostra animação de clique (ícone do botão direito)
signal show_click_animation()

## Mostra aviso de ferramenta errada
signal show_action_warning(label: String)
