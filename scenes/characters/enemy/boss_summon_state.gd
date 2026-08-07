extends NodeState

## Estado de invocação para bosses (ex: Necromante)
## Invoca inimigos menores ao redor do boss com efeito de portal

var enemy: Enemy
var animated_sprite_2d: AnimatedSprite2D

var controle_de_animacao_ativo: bool = true

## Cenas dos inimigos que podem ser invocados
@export var summon_scenes: Array[PackedScene] = []

## Quantidade de inimigos a invocar por ciclo
@export var summon_count: int = 2

## Offsets de spawn relativos à posição do boss
@export var spawn_offsets: Array[Vector2] = [
	Vector2(-40, 0),
	Vector2(40, 0),
	Vector2(-25, -35),
	Vector2(25, -35),
	Vector2(0, -50),
]

## Delay antes de começar a spawnar (sincronizado com animação de ataque)
@export var summon_delay: float = 1.5

## Intervalo entre cada inimigo spawnado
@export var spawn_interval: float = 0.4

## Tempo total do estado após o summon (cooldown visual)
@export var state_duration: float = 4.0

## Quantos ciclos de invocação o boss pode fazer (1 = invoca apenas uma vez)
@export var max_summon_cycles: int = 1

## Cooldown entre summons (gerenciado pelo Enemy.attack_cooldown)
## Este estado usa enemy.last_attack_time para respeitar o cooldown

var _time_in_state: float = 0.0
var _summon_started: bool = false
var _summon_executed: bool = false
var _spawn_counter: int = 0
var _spawn_timer: float = 0.0
var _summon_cycles_done: int = 0
var _vanishing: bool = false


func _ready() -> void:
	if EventBus:
		EventBus.player_died.connect(_on_player_died)


func _on_enter() -> void:
	enemy = owner as Enemy
	if enemy:
		animated_sprite_2d = enemy.get_node("AnimatedSprite2D")
		print("💀 [BOSS SUMMON] _on_enter - enemy.player = ", enemy.player.name if enemy.player else "NULL")
	
	# Se já atingiu o limite de summons, desabilita ataque e sai
	if _summon_cycles_done >= max_summon_cycles:
		print("💀 [BOSS SUMMON] Limite de summons atingido (", max_summon_cycles, ")! Boss não invocará mais.")
		if enemy:
			enemy.can_attack = false
		return
	
	_time_in_state = 0.0
	_summon_started = false
	_summon_executed = false
	_spawn_counter = 0
	_spawn_timer = 0.0
	
	# Toca a animação de "attack" como ritual de invocação
	if animated_sprite_2d:
		animated_sprite_2d.play("attack")
	
	# Registra o tempo do ataque para cooldown
	if enemy:
		enemy.last_attack_time = Time.get_ticks_msec() / 1000.0
	
	# 🔊 Toca som de invocação
	var sfx = enemy.get_node_or_null("SFXComponent")
	if sfx:
		sfx.summon_triggered.emit()
	else:
		print("💀 [BOSS SUMMON] ⚠️ SFXComponent não encontrado em ", enemy.name)
	
	print("💀 [BOSS SUMMON] Iniciando ritual de invocação...")


func _on_process(delta: float) -> void:
	if enemy and enemy.is_dead:
		return
	if not controle_de_animacao_ativo:
		return
	if _vanishing:
		return
	
	_time_in_state += delta
	
	# Inicia o summon após o delay da animação
	if not _summon_started and _time_in_state >= summon_delay:
		_summon_started = true
		_spawn_counter = 0
		_spawn_timer = 0.0
		print("💀 [BOSS SUMMON] Começando a invocar inimigos!")
	
	# Spawna inimigos um por um com intervalo
	if _summon_started and not _summon_executed:
		_spawn_timer += delta
		if _spawn_timer >= spawn_interval and _spawn_counter < summon_count:
			_spawn_timer = 0.0
			_spawn_one_enemy(_spawn_counter)
			_spawn_counter += 1
		
		if _spawn_counter >= summon_count:
			_summon_executed = true
			print("💀 [BOSS SUMMON] Invocação concluída! ", summon_count, " inimigos invocados.")
	
	# Sai do estado após a duração total
	if _time_in_state >= state_duration:
		_summon_cycles_done += 1
		if _summon_cycles_done >= max_summon_cycles:
			print("💀 [BOSS SUMMON] Último ciclo concluído! Boss vai desaparecer...")
			if enemy:
				enemy.can_attack = false
			# Faz o boss desaparecer com efeito de portal (igual à morte)
			_vanishing = true
			if enemy:
				enemy.desaparecer()
			transition.emit("idle")
		else:
			transition.emit("chase")


## Spawna um único inimigo na posição designada
func _spawn_one_enemy(index: int) -> void:
	if not enemy or summon_scenes.is_empty():
		return
	
	# Escolhe uma cena (aleatória ou cíclica)
	var scene = summon_scenes[index % summon_scenes.size()]
	var spawned_enemy = scene.instantiate()
	
	# Define posição de spawn relativa ao boss
	var offset = spawn_offsets[index % spawn_offsets.size()]
	spawned_enemy.global_position = enemy.global_position + offset
	
	# 🔍 DEBUG: verifica estado do boss antes do spawn
	print("💀 [BOSS SUMMON] Spawn #", index + 1, " | Boss player: ", enemy.player.name if enemy.player else "NULL")
	print("💀 [BOSS SUMMON] Spawn #", index + 1, " | Grupo 'player' tem ", get_tree().get_nodes_in_group("player").size(), " nós")
	
	# Adiciona ao mesmo parent do boss (a cena do nível)
	# ⚠️ add_child dispara _ready() que tenta encontrar o player via grupo
	enemy.get_parent().add_child(spawned_enemy)
	
	# 🔧 Força o player do inimigo spawnado a ser o mesmo player que o boss está mirando
	# (sobrescreve qualquer valor que _ready() possa ter definido incorretamente)
	if enemy.player:
		spawned_enemy.player = enemy.player
		print("💀 [BOSS SUMMON] ✓ player FORÇADO para: ", enemy.player.name)
	else:
		print("💀 [BOSS SUMMON] ❌ Boss está sem player! Tentando achar via grupo...")
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			spawned_enemy.player = players[0]
			print("💀 [BOSS SUMMON] ✓ player encontrado via grupo: ", players[0].name)
		else:
			print("💀 [BOSS SUMMON] ❌ Nenhum nó no grupo 'player'! O player existe na cena?")
	
	print("💀 [BOSS SUMMON] Inimigo #", index + 1, " invocado | Alvo FINAL: ", spawned_enemy.player.name if spawned_enemy.player else "NULL")


func _on_physics_process(_delta: float) -> void:
	if enemy and enemy.is_dead:
		return
	if not controle_de_animacao_ativo:
		return
	
	# Boss fica parado enquanto invoca, mas olha para o player
	if enemy and enemy.player:
		var direction = enemy.get_direction_to_player()
		if direction != Vector2.ZERO:
			enemy.enemy_direction = direction
			enemy.update_flip(direction)


func _on_next_transitions() -> void:
	if enemy == null:
		enemy = owner as Enemy
	
	if enemy and enemy.is_dead:
		return
	
	if not controle_de_animacao_ativo or not enemy.player:
		return


func _on_exit() -> void:
	if animated_sprite_2d:
		animated_sprite_2d.stop()


func _on_player_died() -> void:
	controle_de_animacao_ativo = false
