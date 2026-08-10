class_name Enemy
extends CharacterBody2D

## Classe principal do inimigo
## Gerencia o inimigo controlado por IA com máquina de estados

@onready var hit_component: HitComponent = $HitComponent

## Componente que detecta quando o inimigo é atingido por flechas (Crossbow)
@onready var hurt_component: HurtComponent = $HurtComponent

## Velocidade de movimentação do inimigo
@export var chase_speed: float = 50.0

## Vida do inimigo
@export var max_health: float = 80.0
var current_health: float = 80.0

## Distância mínima para começar a perseguir o player
@export var chase_distance: float = 200.0

## Distância para atacar o player
@export var attack_distance: float = 30.0

## Direção que o inimigo está olhando
var enemy_direction: Vector2 = Vector2.DOWN

## Referência ao player
var player: Node2D = null

## Variável de controle para o inimigo morrer
var is_dead: bool = false

## Controle para bosses: se false, o chase state NÃO transita para attack
## Usado pelo boss_summon_state para limitar invocações a 1 ciclo
var can_attack: bool = true

## Orientação NATURAL do sprite nos arquivos de arte:
##   true  = sprite desenhado olhando para a DIREITA → (Necromante)
##   false = sprite desenhado olhando para a ESQUERDA → (MushMario)
## Basta configurar UMA vez na cena .tscn, nunca mais mexe.
@export var sprite_faces_right: bool = false

## Tipo de inimigo (usado para registro e comportamentos especiais)
## Ex: "Necromante", "MushMario", "" (genérico)
@export var enemy_type: String = ""

## Referência à sprite animada
var animated_sprite_2d: AnimatedSprite2D

## Referência ao collision shape do hit component
var hit_component_collision_shape: CollisionShape2D

## Posição padrão do hitbox (usada para reset)
var _hitbox_default_position: Vector2 = Vector2.ZERO

# --- SISTEMA DE SPAWN COM PORTAL ---
## Componente reutilizável de spawn via portal
@onready var portal_spawn_component: PortalSpawnComponent = $PortalSpawnComponent

## Se o inimigo está na animação de spawn (começa true para evitar que o idle toque animação antes do spawn)
var _is_spawning: bool = true

## Timer pós-spawn: impede transições por um curto período após o spawn terminar
var _post_spawn_cooldown: float = 0.0

## Tempo (em segundos) que o inimigo permanece na animação "fade" após o portal sumir
@export var post_spawn_delay: float = 0.4

## Tempo do último ataque (usado para cooldown entre ataques)
var last_attack_time: float = -9999.0

## Tempo de cooldown entre ataques consecutivos
@export var attack_cooldown: float = 1.5


func _ready() -> void:
	# Busca o player na cena através do grupo
	var players = get_tree().get_nodes_in_group("player")
	print("👹 [ENEMY] _ready() de ", name, " | Grupo 'player' tem ", players.size(), " nós")
	if players.size() > 0:
		player = players[0]
		print("👹 [ENEMY] ", name, " - Player encontrado: ", player.name)
	else:
		print("❌ [ENEMY] ", name, " - Player NÃO encontrado! Nós na árvore: ", get_tree().root.get_child_count())
	
	# Adicionar inimigo ao grupo de inimigos
	add_to_group("enemies")
	print("👹 [ENEMY] ", name, " adicionado ao grupo 'enemies'")
	
	# Registra aparição do Necromante no registro global
	if enemy_type == "Necromante":
		NecromancerRegistry.register_appearance()
	
	# Conectar ao sinal de morte do player para parar quando player morre
	if EventBus:
		EventBus.player_died.connect(_on_player_died)
	
	# Conecta ao sinal de dano recebido (ex: flechas da besta)
	hurt_component.hurt.connect(on_hurt)
	
	# Obter referência à sprite e sincronizar estado inicial
	animated_sprite_2d = get_node("AnimatedSprite2D")
	# Garante que flip_h comece alinhado com sprite_faces_right
	if animated_sprite_2d:
		animated_sprite_2d.flip_h = not sprite_faces_right
	
	# Obter referência ao collision shape do hit component
	hit_component_collision_shape = get_node("HitComponent/HitComponentCollisionShape2D")
	_hitbox_default_position = hit_component_collision_shape.position
	
	# Configura o componente de spawn (se existir)
	if portal_spawn_component:
		portal_spawn_component.spawn_complete.connect(_on_spawn_complete)
		# Desabilita colisões e física durante o spawn para evitar
		# que o inimigo colida com o boss que o invocou
		portal_spawn_component.disable_collisions = [
			$CollisionShape2D,
			$HurtComponent/CollisionShape2D,
			$HitComponent/HitComponentCollisionShape2D,
		]
		portal_spawn_component.disable_physics_on = [self]
		portal_spawn_component.play_spawn()
	else:
		# Sem portal: libera o idle imediatamente e toca animação
		_is_spawning = false
		if animated_sprite_2d:
			animated_sprite_2d.play("idle")
	
	print("👹 [ENEMY] ", name, " inicializado | player=", player.name if player else "NULL", " | Chase: ", chase_distance, " | Attack: ", attack_distance)


## Toca a animação do inimigo emergindo de um portal (delega ao PortalSpawnComponent)
func _play_spawn_animation() -> void:
	if portal_spawn_component:
		portal_spawn_component.play_spawn()
		_is_spawning = true


## Callback chamado quando a animação de spawn termina
func _on_spawn_complete() -> void:
	_is_spawning = false
	_post_spawn_cooldown = post_spawn_delay
	
	# Reativa colisões
	if hit_component_collision_shape:
		hit_component_collision_shape.disabled = true  # fica desabilitado até o ataque
	
	if hurt_component:
		var hurt_shape = hurt_component.get_node_or_null("CollisionShape2D")
		if hurt_shape:
			hurt_shape.disabled = false
	
	print("👹 [ENEMY] Spawn completo! Inimigo ativo.")


func _physics_process(delta: float) -> void:
	# Decrementa o cooldown pós-spawn
	if _post_spawn_cooldown > 0.0:
		_post_spawn_cooldown -= delta


## Habilita o hitbox de ataque
## Deve ser chamado pelo AttackState no _on_enter()
func enable_hit_box() -> void:
	if hit_component_collision_shape == null:
		return
	# Aplica o flip atual (posição X correta baseada na direção)
	_apply_hitbox_flip_position()
	hit_component_collision_shape.disabled = false


## Desabilita o hitbox de ataque e reseta posição
## Deve ser chamado pelo AttackState no _on_exit() e pelo ChaseState
func disable_hit_box() -> void:
	if hit_component_collision_shape == null:
		return
	hit_component_collision_shape.disabled = true
	hit_component_collision_shape.position = _hitbox_default_position


## Aplica a posição X do hitbox baseada no flip atual e na orientação padrão do sprite (uso interno)
func _apply_hitbox_flip_position() -> void:
	if hit_component_collision_shape == null or animated_sprite_2d == null:
		return
	
	# Lado real: sprite_faces_right XOR flip_h
	var actually_facing_right: bool = (sprite_faces_right != animated_sprite_2d.flip_h)
	
	if actually_facing_right:
		hit_component_collision_shape.position.x = 26
	else:
		hit_component_collision_shape.position.x = -26


## Calcula a distância até o player
func get_distance_to_player() -> float:
	if player == null:
		return 999999.0
	return global_position.distance_to(player.global_position)


## Calcula a direção até o player
func get_direction_to_player() -> Vector2:
	if player == null:
		return Vector2.ZERO
	return (player.global_position - global_position).normalized()


## Função para adicionar vida
func adicionar_vida(quantidade: float) -> void:
	current_health = clampf(current_health + quantidade, 0.0, max_health)
	
	if current_health <= 0.0:
		morrer()


## Callback chamado quando o HurtComponent recebe dano (ex: flecha da besta)
func on_hurt(hit_damage: int) -> void:
	print("👹 [ENEMY] Recebeu ", hit_damage, " de dano! Vida atual: ", current_health)
	adicionar_vida(-hit_damage)


## Função para morrer
func morrer() -> void:
	if is_dead:
		return
	is_dead = true
	print("👹 Inimigo derrotado!")
	
	# Emite sinal de morte (opcional, para futuras conquistas/XP)
	#EventBus.enemy_died.emit()
	
	set_physics_process(false)
	
	# Desabilita hitbox de ataque
	disable_hit_box()
	
	# Desabilita hurtbox (não pode mais tomar dano)
	if hurt_component:
		var hurt_shape = hurt_component.get_node_or_null("CollisionShape2D")
		if hurt_shape:
			hurt_shape.disabled = true
	
	# Desliga aura (partículas de buff do necromante)
	var up_aura = get_node_or_null("UpAura") as GPUParticles2D
	if up_aura:
		up_aura.emitting = false
	var down_aura = get_node_or_null("DownAura") as GPUParticles2D
	if down_aura:
		down_aura.emitting = false
	
	# Ativa portal de despawning (partículas reaparecem enquanto ele morre)
	if portal_spawn_component:
		if portal_spawn_component.portal_particles:
			portal_spawn_component.portal_particles.emitting = true
			portal_spawn_component.portal_particles.restart()
		if portal_spawn_component.portal_particles2:
			portal_spawn_component.portal_particles2.emitting = true
			portal_spawn_component.portal_particles2.restart()
	
	# Toca animação "fade" ao contrário (frame 8 → 0)
	if animated_sprite_2d:
		var sprite_frames = animated_sprite_2d.sprite_frames
		if sprite_frames and sprite_frames.has_animation("fade"):
			var frame_count: int = sprite_frames.get_frame_count("fade")
			# Calcula duração total: frames / (anim_speed * speed_scale)
			var anim_speed: float = sprite_frames.get_animation_speed("fade")
			var current_scale: float = abs(animated_sprite_2d.speed_scale)
			var duration: float = frame_count / (anim_speed * current_scale)
			
			# Garante que a animação não vai loopar durante o reverse
			sprite_frames.set_animation_loop("fade", false)
			
			# Começa do último frame e toca ao contrário
			animated_sprite_2d.frame = frame_count - 1
			animated_sprite_2d.speed_scale = -current_scale
			animated_sprite_2d.play("fade")
			
			# Aguarda a duração total da animação reversa
			await get_tree().create_timer(duration).timeout
	
	queue_free()


## Faz o inimigo desaparecer com efeito de portal (igual à morte)
## Usado pelo boss_summon_state quando o ciclo de invocação termina
func desaparecer() -> void:
	if is_dead:
		return
	is_dead = true
	print("👹 ", name, " desaparecendo após invocação!")
	
	# Notifica o registro que o Necromante desapareceu
	if enemy_type == "Necromante":
		NecromancerRegistry.necromancer_vanished.emit(NecromancerRegistry.total_appearances)
	
	set_physics_process(false)
	
	# Desabilita hitbox de ataque
	disable_hit_box()
	
	# Desabilita hurtbox (não pode mais tomar dano)
	if hurt_component:
		var hurt_shape = hurt_component.get_node_or_null("CollisionShape2D")
		if hurt_shape:
			hurt_shape.disabled = true
	
	# Desliga aura (partículas de buff do necromante)
	var up_aura = get_node_or_null("UpAura") as GPUParticles2D
	if up_aura:
		up_aura.emitting = false
	var down_aura = get_node_or_null("DownAura") as GPUParticles2D
	if down_aura:
		down_aura.emitting = false
	
	# Ativa portal de despawning
	if portal_spawn_component:
		if portal_spawn_component.portal_particles:
			portal_spawn_component.portal_particles.emitting = true
			portal_spawn_component.portal_particles.restart()
		if portal_spawn_component.portal_particles2:
			portal_spawn_component.portal_particles2.emitting = true
			portal_spawn_component.portal_particles2.restart()
	
	# Toca animação "fade" ao contrário (frame final → 0)
	if animated_sprite_2d:
		var sprite_frames = animated_sprite_2d.sprite_frames
		if sprite_frames and sprite_frames.has_animation("fade"):
			var frame_count: int = sprite_frames.get_frame_count("fade")
			var anim_speed: float = sprite_frames.get_animation_speed("fade")
			var current_scale: float = abs(animated_sprite_2d.speed_scale)
			var duration: float = frame_count / (anim_speed * current_scale)
			
			sprite_frames.set_animation_loop("fade", false)
			
			animated_sprite_2d.frame = frame_count - 1
			animated_sprite_2d.speed_scale = -current_scale
			animated_sprite_2d.play("fade")
			
			await get_tree().create_timer(duration).timeout
	
	queue_free()


## Atualiza o flip da sprite para olhar na direção do movimento.
## Lê/escreve flip_h DIRETAMENTE — nunca dessincroniza.
func update_flip(direction: Vector2) -> void:
	if direction == Vector2.ZERO or animated_sprite_2d == null:
		return
	
	var moving_right: bool = direction.x > 0
	# Flip necessário: inverte se a direção do movimento for oposta à orientação natural
	animated_sprite_2d.flip_h = (moving_right != sprite_faces_right)
	_apply_hitbox_flip_position()


## Callback quando o player morre
func _on_player_died() -> void:
	set_physics_process(false)
