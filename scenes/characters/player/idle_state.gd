extends NodeState

var player: Player
var animated_sprite_2d: AnimatedSprite2D
# Dentro do SEU script de transições:
var controle_de_animacao_ativo: bool = true

func _ready() -> void:
	# Se conecta ao sinal de morte
	EventBus.player_died.connect(_on_player_died)
	
## Executado quando o estado idle é iniciado
## Obtém as referências do player e do sprite animado
## Inicia a animação padrão de idle frontal
func _on_enter() -> void:
	# Pega as referências dos nós quando o estado é ativado
	player = owner as CharacterBody2D
	animated_sprite_2d = player.get_node("AnimatedSprite2D")
	if animated_sprite_2d:
		animated_sprite_2d.play("idle_front")


## Processa a lógica do estado a cada frame
## Atualmente não implementado para este estado
func _on_process(_delta: float) -> void:
	pass


## Processa a física do estado a cada frame
## Atualiza a animação idle baseado na direção que o jogador está olhando
func _on_physics_process(_delta: float) -> void:	
	if not controle_de_animacao_ativo: 
		return # Se o player morreu, não deixa o script rodar mais nada!	
	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("idle_back")
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("idle_front")
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("idle_left")
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("idle_right")


## Verifica condições para transição para outros estados
## Transita para walk se houver input de movimento
## Transita para estados de ferramentas (Chopping, Tilling, Watering) baseado na ferramenta equipada e input de uso
func _on_next_transitions() -> void:
	# Se houver movimentação chama a transição andando	
	# Se clicar com o botão esquerdo do mouse chama a animação correspondente
	GameInputEvents.movement_input()
	if GameInputEvents.is_moviment_input():
		transition.emit("walk")
	if player.current_tool == DataTypes.Tools.AxeWood && GameInputEvents.use_tool():
		transition.emit("Chopping")
	if player.current_tool == DataTypes.Tools.TillGround && GameInputEvents.use_tool():
		transition.emit("Tilling")
	if player.current_tool == DataTypes.Tools.WaterCrops && GameInputEvents.use_tool():
		print("💧 Transição para Watering solicitada")
		transition.emit("Watering")	


## Executado quando o estado idle é finalizado
## Para a animação atual
func _on_exit() -> void:
	animated_sprite_2d.stop()
func _on_player_died() -> void:
	controle_de_animacao_ativo = false # Desativa o controle normal de andar/correr
	animated_sprite_2d.play("idle_dead")
