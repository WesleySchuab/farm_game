# AudioManager.gd
extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var on_the_farm_music = preload("res://audio/music/on_the_farm_music.tscn")
var current_level_audio_player = null


func _ready() -> void:
	await get_tree().process_frame
	
	# Cria os players dinamicamente se não existirem
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		music_player.name = "MusicPlayer"
		add_child(music_player)
	
	if sfx_player == null:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer"
		add_child(sfx_player)


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
	"""Toca um efeito sonoro"""
	sfx_player.stream = stream
	sfx_player.play()


func stop_sfx() -> void:
	"""Para o efeito sonoro"""
	if sfx_player.playing:
		sfx_player.stop()


func stop_all() -> void:
	"""Para todos os áudios"""
	music_player.stop()
	sfx_player.stop()
	# Adicione aqui outros players que queira silenciar


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
