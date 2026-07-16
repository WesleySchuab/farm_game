# AudioManager.gd
extends Node

# Players principais
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Pool de efeitos sonoros 2D para animais/objetos
var sfx_pool_2d: Array[AudioStreamPlayer2D] = []
var sfx_pool_size: int = 10  # Quantidade de players no pool

var on_the_farm_music = preload("res://audio/music/on_the_farm_music.tscn")
var current_level_audio_player = null


func _ready() -> void:
	await get_tree().process_frame
	
	# Cria os players principais
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		music_player.name = "MusicPlayer"
		add_child(music_player)
	
	if sfx_player == null:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer"
		add_child(sfx_player)
	
	# Inicializa o pool de sons 2D para animais/objetos
	_initialize_sfx_pool_2d()


func _initialize_sfx_pool_2d() -> void:
	"""Cria o pool de AudioStreamPlayer2D para efeitos sonoros de animais/objetos"""
	for i in range(sfx_pool_size):
		var player = AudioStreamPlayer2D.new()
		player.name = "SFXPoolPlayer2D_%d" % i
		add_child(player)
		sfx_pool_2d.append(player)


func play_music(stream: AudioStream) -> void:
	"""Toca uma música de áudio"""
	if music_player.stream == stream and music_player.playing:
		return # Já está tocando esta música
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	"""Para a música atual"""
	if music_player.playing:
		music_player.stop()


func play_sfx(stream: AudioStream) -> void:
	"""Toca um efeito sonoro (2D global)"""
	sfx_player.stream = stream
	sfx_player.play()


func play_sfx_2d(stream: AudioStream, position: Vector2, volume_db: float = 0.0) -> void:
	"""
	Toca um efeito sonoro 2D usando o pool de players
	Útil para sons de animais, colisões, etc que vêm de uma posição específica
	
	Uso:
		AudioManager.play_sfx_2d(som_vaca, global_position)
	"""
	var available_player = _get_available_sfx_player_2d()
	if available_player:
		available_player.stream = stream
		available_player.global_position = position
		available_player.volume_db = volume_db
		available_player.play()


func _get_available_sfx_player_2d() -> AudioStreamPlayer2D:
	"""Retorna um player 2D disponível do pool, reutilizando se necessário"""
	# Primeiro, tenta encontrar um player que não está tocando
	for player in sfx_pool_2d:
		if not player.playing:
			return player
	
	# Se todos estão tocando, retorna o primeiro (vai ser reutilizado)
	if sfx_pool_2d.size() > 0:
		return sfx_pool_2d[0]
	
	return null


func stop_sfx() -> void:
	"""Para o efeito sonoro"""
	if sfx_player.playing:
		sfx_player.stop()


func stop_all() -> void:
	"""Para todos os áudios"""
	music_player.stop()
	sfx_player.stop()
	
	# Para todos os players do pool 2D
	for player in sfx_pool_2d:
		if player.playing:
			player.stop()


func play_level_music() -> void:
	"""Inicia a música do nível"""
	if current_level_audio_player == null:
		current_level_audio_player = on_the_farm_music.instantiate()
		add_child(current_level_audio_player)
	
	if current_level_audio_player and not current_level_audio_player.playing:
		current_level_audio_player.play()


func stop_level_music() -> void:
	"""Para a música do nível"""
	if current_level_audio_player and current_level_audio_player.playing:
		current_level_audio_player.stop()


func stop_all_audio_in_scene() -> void:
	"""Para TODOS os áudios da cena (música, animais, efeitos, etc)"""
	# Para AudioStreamPlayer globais
	stop_all()
	
	# Para a música do nível
	stop_level_music()
	
	# Busca e para todos os AudioStreamPlayers na árvore
	var tree_root = get_tree().root
	_stop_audio_recursive(tree_root)


func _stop_audio_recursive(node: Node) -> void:
	"""Recursivamente para todos os AudioStreamPlayers"""
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		if node.playing:
			node.stop()
	
	# Recurse para filhos
	for child in node.get_children():
		_stop_audio_recursive(child)
