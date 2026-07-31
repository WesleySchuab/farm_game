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
## Inicia a animação idle correta baseada na ferramenta equipada
func _on_enter() -> void:
	# Pega as referências dos nós quando o estado é ativado
	player = owner as CharacterBody2D
	animated_sprite_2d = player.get_node("AnimatedSprite2D")
	if animated_sprite_2d:
		var prefix: String = "crossbow_idle_" if player.current_tool == DataTypes.Tools.Crossbow else "idle_"
		animated_sprite_2d.play(prefix + "front")


## Processa a lógica do estado a cada frame
## Atualmente não implementado para este estado
func _on_process(_delta: float) -> void:
	pass


## Processa a física do estado a cada frame
## Atualiza a animação idle baseado na direção que o jogador está olhando
## Usa animações "crossbow_idle_*" quando a besta está equipada
func _on_physics_process(_delta: float) -> void:	
	if not controle_de_animacao_ativo: 
		return # Se o player morreu, não deixa o script rodar mais nada!
	var prefix: String = "crossbow_idle_" if player.current_tool == DataTypes.Tools.Crossbow else "idle_"
	var target_animation: String = prefix + "front"
	if player.player_direction == Vector2.UP:
		target_animation = prefix + "back"
	elif player.player_direction == Vector2.DOWN:
		target_animation = prefix + "front"
	elif player.player_direction == Vector2.LEFT:
		target_animation = prefix + "left"
	elif player.player_direction == Vector2.RIGHT:
		target_animation = prefix + "right"
	
	if animated_sprite_2d.animation != target_animation:
		animated_sprite_2d.play(target_animation)


## Verifica condições para transição para outros estados
## Transita para walk se houver input de movimento
## Transita para estados de ferramentas (Chopping, Tilling, Watering) baseado na ferramenta equipada e input de uso
func _on_next_transitions() -> void:
	# ⏸️ KNOCKBACK ATIVO — não transiciona para walk nem ferramentas
	if player.knockback_velocity != Vector2.ZERO:
		return
	
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
	if player.current_tool == DataTypes.Tools.Crossbow && GameInputEvents.use_tool():
		transition.emit("Crossbow")


## Executado quando o estado idle é finalizado
## Para a animação atual
func _on_exit() -> void:
	animated_sprite_2d.stop()
func _on_player_died() -> void:
	controle_de_animacao_ativo = false # Desativa o controle normal de andar/correr
	animated_sprite_2d.play("idle_dead")
