---
name: fallen-realm-2-dev
description: 'Fluxos de trabalho do jogo Fallen Realm 2 (Godot 4). Use when: adicionar ferramenta, cultura/planta, inimigo, som/música, ação de diálogo, coletável, ou conectar sistemas via EventBus neste projeto.'
argument-hint: '[ferramenta|cultura|inimigo|som|dialogo|coletavel]'
---

# Fallen Realm 2 — Fluxos de trabalho

Godot 4, jogo de fazenda. Antes de codar, consulte o mapa de arquitetura em `AGENTS.md` (raiz) e a memória `/memories/repo/conventions.md` para convenções detalhadas.

## Regras de ouro
- Comunicação entre sistemas: **sempre via `EventBus`** (`scripts/globais/EventBus.gd`). Nunca referência direta entre sistemas.
- Classes PascalCase; funções/variáveis snake_case; privados com `_`; sinais snake_case no passado.
- Debug: emoji + `[SISTEMA]` no print (ex.: `👹[ENEMY]`, `🔥[CAMPFIRE]`, `🎵[AUDIO]`).
- Depois de implementar, atualize `AGENTS.md` e a memória do repositório se mudou a arquitetura.

## 1. Adicionar uma ferramenta
1. `scripts/globais/data_types.gd`: adicionar valor no enum `Tools` (ordem importa).
2. `scenes/ui/tools_painel.tscn`: adicionar `Button` em `MarginContainer/HBoxContainer` com `theme_type_variation = &"ToolButton"`, `icon` (AtlasTexture), `icon_alignment = 1`, `expand_icon = true`.
3. `scenes/ui/tools_painel.gd`: adicionar `@onready var tool_x: Button` + `_on_tool_x_pressed()` chamando `ToolManager.select_tool(DataTypes.Tools.Xxx)`; ligar o sinal `pressed` no `.tscn`.
4. Se a ferramenta age no mundo, criar/linkar o cursor component correspondente (ex.: `field_cursor_component.gd`, `crop_cursor_component.gd`, `rock_barrier_cursor_component.gd`).

## 2. Adicionar uma cultura/planta
1. Criar `scenes/objects/plants/<nome>.tscn` copiando `corn.tscn` (Sprite2D com `basic_plants.png`, WateringParticles, FloringParticles, GrowthCycleComponent, HurtComponent, SaveDataComponent).
2. Criar script `<nome>.gd` copiando `corn.gd` (mapa `growth_frames`, rega em `on_hurt`, colheita em `on_crop_harvesting`).
3. Adicionar valor no enum `Tools` (PlantX).
4. Em `scenes/components/crop_cursor_component.gd`: preload da cena, branch em `_auto_plant_if_on_tilled_soil()` e `_plant_crop_at_cell()`.
5. Plantio é automático ao pisar em solo arado; novas plantas devem receber `is_watered = false`.

## 3. Adicionar um inimigo
1. Criar cena `scenes/characters/enemy/<nome>.tscn` com script `enemy.gd` (classe `Enemy`).
2. Filhos obrigatórios: `HitComponent`, `HurtComponent`, `PortalSpawnComponent`, `AnimatedSprite2D` (+ collision shapes).
3. Configurar exports na cena: `enemy_type`, `sprite_faces_right`, `max_health`, `chase_speed`, `chase_distance`, `attack_distance`.
4. Adicionar a instância no level `.tscn` desejado; barra de vida é criada automaticamente em `_create_health_bar()`.
5. Comportamentos novos: criar estados na pasta `scenes/characters/enemy/` seguindo o padrão `NodeState`.

## 4. Adicionar som (SFX) ou música
1. `scripts/globais/audio_manager.gd`: adicionar ao enum `SFX` + dicionário `SFX_PATHS` (ou `MUSIC` + `MUSIC_PATHS`).
2. Chamar `AudioManager.play_sfx_at(SFX.X, pos, vol_db)` / `play_sfx(id, vol_db)` / `play_music(id, vol_db, pitch)`.
3. Arquivos em `game/assets/audio/sfx/*.ogg` (SFX) e `game/assets/audio/music/*` (música).

## 5. Adicionar ação de diálogo
1. `scripts/globais/game_dialogue_manager.gd`: adicionar `signal xxx` + `func action_xxx() -> void: xxx.emit()`.
2. No sistema que reage: conectar no sinal (`GameDialogueManager.xxx.connect(...)`).
3. No `.dialogue` (`dialogue/conversations/*.dialogue`): `do GameDialogueManager.action_xxx()`.
4. Recompensa só deve marcar quest concluída quando entregue de fato (permite re-conversar se recusar).

## 6. Adicionar um coletável
1. Criar cena do drop (ex.: `scenes/objects/stone.tscn`) com `CollectableComponent` (Area2D layer 32, mask 2).
2. O coletável entra no inventário via `InventoryManager.add_collectable(nome)` no `_on_body_entered`.
3. O objeto que dropa chama a cena no `on_hurt`/colheita (ex.: `rock.gd`, `tree.gd`, `corn.gd`).

## 7. Conectar sistemas via EventBus
1. `scripts/globais/EventBus.gd`: declarar `signal nome(params)`.
2. Emissor: `EventBus.nome.emit(...)`.
3. Receptor: `EventBus.nome.connect(_on_nome)` no `_ready`.
