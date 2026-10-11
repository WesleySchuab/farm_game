## Estado de regar as plantações
## Gerencia a animação e comportamento quando o jogador usa o regador
extends NodeState

## Referência ao jogador
@export var player: Player

## Referência ao componente de sprite animado
@export var animated_sprite_2d : AnimatedSprite2D

## Velocidade de movimento enquanto rega
@export var speed: int = 50

## Inicializa o estado de aguar
## Desabilita a colisão do componente de ataque e reseta sua posição
func  _ready() -> void:
	print("💧 Watering state _ready.")
	player.disable_player_hitbox()


## Processa a lógica do estado a cada frame
## Atualmente não implementado para este estado
func _on_process(_delta : float) -> void:
	pass


## Processa a física do estado a cada frame
## Mantém o player se movendo (para alcançar as plantas) e o hitbox ativo
func _on_physics_process(_delta : float) -> void:
	if not player.movement_enabled:
		player.velocity = Vector2.ZERO
		return

	if player.knockback_velocity != Vector2.ZERO:
		return

	var direction: Vector2 = GameInputEvents.movement_input()
	if direction != Vector2.ZERO:
		player.player_direction = direction
		_play_watering_animation()

	# Mantém o hitbox posicionado e ativo na direção do player
	player.set_hitbox_position(
		Vector2(6, -16),   # UP
		Vector2(21, -3),   # RIGHT
		Vector2(-5, 6),    # DOWN
		Vector2(-21, 3)    # LEFT
	)
	player.enable_player_hitbox()

	player.velocity = direction * speed
	player.move_and_slide()

## Executado quando o estado é iniciado
## Determina a animação de regar baseado na direção que o jogador está olhando
func _on_enter() -> void:
	print("💧 Estado Watering ativado.")
	_play_watering_animation()
	
	# Posiciona o hitbox via método centralizado do Player
	player.set_hitbox_position(
		Vector2(6, -16),   # UP
		Vector2(21, -3),   # RIGHT
		Vector2(-5, 6),    # DOWN
		Vector2(-21, 3)    # LEFT
	)
	player.enable_player_hitbox()
	print("💧 Collision habilitada.")


## Toca a animação de regar conforme a direção (fica em loop)
func _play_watering_animation() -> void:
	var anim_name: String = "watering_front"
	if player.player_direction == Vector2.UP:
		anim_name = "watering_back"
	elif player.player_direction == Vector2.RIGHT:
		anim_name = "watering_right"
	elif player.player_direction == Vector2.DOWN:
		anim_name = "watering_front"
	elif player.player_direction == Vector2.LEFT:
		anim_name = "watering_left"
	animated_sprite_2d.play(anim_name)

## Verifica condições para transição para o próximo estado
## Sai do estado quando o jogador trocar de ferramenta ou sair de perto das culturas
func _on_next_transitions() -> void:
	if player.current_tool != DataTypes.Tools.WaterCrops:
		transition.emit("idle")
		return
	# Fora da área de plantio -> volta ao normal
	if not player.is_near_unwatered_crop():
		transition.emit("idle")
		
## Executado quando o estado é finalizado
## Para a animação atual
func _on_exit() -> void:
	animated_sprite_2d.stop()
	player.disable_player_hitbox()
	print("💧 Estado Watering desativado")
