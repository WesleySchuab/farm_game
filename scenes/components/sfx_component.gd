# SFXComponent.gd — Componente de som reutilizável
class_name SFXComponent
extends Node

## ──────────────────────────────────────────────
## 🔊 Anexe a qualquer Node2D para tocar sons
## via sinais. Configuração 100% na cena .tscn.
##
## Sinais:
##   attack_triggered  → toca attack_sfx
##   summon_triggered  → toca summon_sfx
##   footstep_triggered → toca footstep_sfx (varied)
## ──────────────────────────────────────────────

@export var pitch_range: float = 0.1
@export var volume_db: float = 0.0
@export var attack_sfx: int = -1
@export var summon_sfx: int = -1
@export var footstep_sfx: int = -1

signal attack_triggered
signal summon_triggered
signal footstep_triggered


func _ready() -> void:
	attack_triggered.connect(_on_attack)
	summon_triggered.connect(_on_summon)
	footstep_triggered.connect(_on_footstep)
	print("🔊 [SFXComponent] Pronto! attack=", attack_sfx, " summon=", summon_sfx, " footstep=", footstep_sfx)


func _on_attack() -> void:
	print("🔊 [SFXComponent] 🎯 attack_triggered → sfx=", attack_sfx)
	if attack_sfx >= 0:
		AudioManager.play_sfx_at(attack_sfx, _owner_pos(), volume_db)


func _on_summon() -> void:
	print("🔊 [SFXComponent] 🎯 summon_triggered → sfx=", summon_sfx)
	if summon_sfx >= 0:
		AudioManager.play_sfx_at(summon_sfx, _owner_pos(), volume_db)


func _on_footstep() -> void:
	print("🔊 [SFXComponent] 🎯 footstep_triggered → sfx=", footstep_sfx)
	if footstep_sfx >= 0:
		AudioManager.play_sfx_varied_at(footstep_sfx, _owner_pos(), pitch_range, volume_db)


func play(id: int) -> void:
	print("🔊 [SFXComponent] 🎯 play → sfx=", id)
	if id >= 0:
		AudioManager.play_sfx_at(id, _owner_pos(), volume_db)


func _owner_pos() -> Vector2:
	var o = get_parent()
	if o is Node2D: return o.global_position
	return Vector2.ZERO
