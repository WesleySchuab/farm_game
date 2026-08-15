# AudioManager.gd — Sistema de áudio centralizado
extends Node

## ──────────────────────────────────────────────
## 🎵 AudioManager — Autoload de áudio do jogo
## ──────────────────────────────────────────────
## Pool 2D com pitch variation + cache de streams.
##
## Uso:
##   AudioManager.play_sfx_at(SFX.FOOTSTEP_1, pos)
##   AudioManager.play_sfx_varied_at(SFX.FOOTSTEP_1, pos)
## ──────────────────────────────────────────────

# ═══════════════════════════════════════════════
# 📁 REGISTRO DE SONS (adicione novos aqui)
# ═══════════════════════════════════════════════
enum SFX {
	# ── Player ──
	FOOTSTEP_1, FOOTSTEP_2, FOOTSTEP_3,
	ARROW_SHOT,
	# ── MushMario ──
	MUSH_ATTACK,
	# ── Necromante ──
	NECRO_SUMMON,
	NECRO_ATTACK,
	# ── Animais ──
	CHICKEN_CLUCK_1, CHICKEN_CLUCK_2, CHICKEN_CLUCK_3,
	COW_MOO,
	# ── Ferramentas ──
	PICKAXE_HIT,
	AXE_HIT,
}

const SFX_PATHS := {
	SFX.FOOTSTEP_1: "res://game/assets/audio/sfx/footstep-1.ogg",
	SFX.FOOTSTEP_2: "res://game/assets/audio/sfx/footstep-2.ogg",
	SFX.FOOTSTEP_3: "res://game/assets/audio/sfx/footstep-3.ogg",
	SFX.ARROW_SHOT: "res://game/assets/audio/sfx/arrow-shot.ogg",
	SFX.MUSH_ATTACK: "res://game/assets/audio/sfx/mush-attack.ogg",
	SFX.NECRO_SUMMON: "res://game/assets/audio/sfx/necro-summon.ogg",
	SFX.NECRO_ATTACK: "res://game/assets/audio/sfx/necro-attack.ogg",
	SFX.CHICKEN_CLUCK_1: "res://game/assets/audio/sfx/chicken-cluck-1.ogg",
	SFX.CHICKEN_CLUCK_2: "res://game/assets/audio/sfx/chicken-cluck-2.ogg",
	SFX.CHICKEN_CLUCK_3: "res://game/assets/audio/sfx/chicken-cluck-3.ogg",
	SFX.COW_MOO: "res://game/assets/audio/sfx/cow-moo.ogg",
	SFX.PICKAXE_HIT: "res://game/assets/audio/music/picareta.mp3",
	SFX.AXE_HIT: "res://game/assets/audio/music/machado.mp3",
}

# Grupos de variação (para play_sfx_varied_at)
const SFX_VARIATIONS := {
	SFX.FOOTSTEP_1: [SFX.FOOTSTEP_1, SFX.FOOTSTEP_2, SFX.FOOTSTEP_3],
	SFX.CHICKEN_CLUCK_1: [SFX.CHICKEN_CLUCK_1, SFX.CHICKEN_CLUCK_2, SFX.CHICKEN_CLUCK_3],
}

var _stream_cache: Dictionary = {}
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var sfx_pool_2d: Array[AudioStreamPlayer2D] = []
const SFX_POOL_SIZE := 16
var on_the_farm_music = preload("res://audio/music/on_the_farm_music.tscn")
var current_level_audio_player = null


func _ready() -> void:
	await get_tree().process_frame
	music_player = _make_player("MusicPlayer", "Music")
	sfx_player = _make_player("SFXPlayer", "SFX")
	for i in SFX_POOL_SIZE:
		var p = AudioStreamPlayer2D.new()
		p.name = "SFXPool_%d" % i
		p.bus = "SFX"
		p.max_polyphony = 1
		add_child(p)
		sfx_pool_2d.append(p)


func _make_player(p_name: String, p_bus: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.name = p_name
	p.bus = p_bus
	add_child(p)
	return p


# ═══════════════════════════════════════════════
# 🎯 API
# ═══════════════════════════════════════════════

## Toca SFX global (UI, menu)
func play_sfx(id: int, vol_db: float = 0.0) -> void:
	_play_on(sfx_player, id, 1.0, vol_db)


## Toca SFX espacial na posição do mundo
func play_sfx_at(id: int, pos: Vector2, vol_db: float = 0.0) -> void:
	var p = _get_free_2d()
	if p: _play_on(p, id, 1.0, vol_db, pos)


## Toca SFX com pitch aleatório (evita fadiga auditiva)
func play_sfx_pitched(id: int, pitch_range: float = 0.1, vol_db: float = 0.0) -> void:
	_play_on(sfx_player, id, randf_range(1.0 - pitch_range, 1.0 + pitch_range), vol_db)


## Toca SFX espacial com pitch aleatório + variação de sample
func play_sfx_varied_at(id: int, pos: Vector2, pitch_range: float = 0.1, vol_db: float = 0.0) -> void:
	var vars: Array = SFX_VARIATIONS.get(id, [])
	if vars.size() > 0:
		id = vars[randi() % vars.size()]
	var p = _get_free_2d()
	if p: _play_on(p, id, randf_range(1.0 - pitch_range, 1.0 + pitch_range), vol_db, pos)


func _play_on(player: Node, id: int, pitch: float, vol: float, pos: Vector2 = Vector2.INF) -> void:
	var stream = _load(id)
	if not stream: return
	if player is AudioStreamPlayer2D and pos != Vector2.INF:
		player.global_position = pos
	player.pitch_scale = pitch
	player.volume_db = vol
	player.stream = stream
	player.play()


func _get_free_2d() -> AudioStreamPlayer2D:
	for p in sfx_pool_2d:
		if not p.playing: return p
	return sfx_pool_2d[0] if sfx_pool_2d.size() > 0 else null


func _load(id: int) -> AudioStream:
	if _stream_cache.has(id): return _stream_cache[id]
	var path: String = SFX_PATHS.get(id, "")
	if path.is_empty() or not FileAccess.file_exists(path):
		push_warning("🎵 [AudioManager] SFX não encontrado id=", id, " → ", path)
		return null
	var s = load(path) as AudioStream
	if s:
		_stream_cache[id] = s
		print("🎵 [AudioManager] SFX carregado: ", path)
	return s


# ═══════════════════════════════════════════════
# 🎵 MÚSICA
# ═══════════════════════════════════════════════
func play_music(stream: AudioStream) -> void:
	if music_player.stream == stream and music_player.playing: return
	music_player.stream = stream
	music_player.play()


func stop_music() -> void: music_player.stop()


func play_level_music() -> void:
	if not current_level_audio_player:
		current_level_audio_player = on_the_farm_music.instantiate()
		add_child(current_level_audio_player)
	if current_level_audio_player and not current_level_audio_player.playing:
		current_level_audio_player.play()


func stop_level_music() -> void:
	if current_level_audio_player and current_level_audio_player.playing:
		current_level_audio_player.stop()


# ═══════════════════════════════════════════════
# 🛑 PARADA
# ═══════════════════════════════════════════════
func stop_all() -> void:
	music_player.stop(); sfx_player.stop()
	for p in sfx_pool_2d:
		if p.playing: p.stop()


## Para apenas os sons 2D do pool (passos, ataques espaciais)
func stop_all_2d() -> void:
	for p in sfx_pool_2d:
		if p.playing: p.stop()


func stop_all_audio_in_scene() -> void:
	stop_all(); stop_level_music()
	_stop_recursive(get_tree().root)


func _stop_recursive(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		if node.playing: node.stop()
	for c in node.get_children(): _stop_recursive(c)


# ═══════════════════════════════════════════════
# 🔧 COMPATIBILIDADE
# ═══════════════════════════════════════════════
func play_sfx_2d(stream: AudioStream, pos: Vector2, vol: float = 0.0) -> void:
	var p = _get_free_2d()
	if p: p.stream = stream; p.global_position = pos; p.volume_db = vol; p.play()


func stop_sfx() -> void:
	if sfx_player.playing: sfx_player.stop()
