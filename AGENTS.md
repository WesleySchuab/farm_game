# Fallen Realm 2 — Guia rápido para o agente

Godot 4, jogo de fazenda. Convenções completas: memória do repositório `/memories/repo/conventions.md`.

## Regras de ouro
- Comunicação entre sistemas: **sempre via `EventBus`** (`scripts/globais/EventBus.gd`). Nunca referência direta entre sistemas.
- Classes PascalCase; funções/variáveis snake_case; privados com `_`; sinais snake_case no passado.
- Grupos em snake_case minúsculo (`"player"`, `"enemies"`).
- Debug: emoji + `[SISTEMA]` no print (ex.: `👹[ENEMY]`, `🔥[CAMPFIRE]`, `🎵[AUDIO]`).

## Autoloads (ordem no project.godot)
| Autoload | Arquivo | Responsabilidade |
|---|---|---|
| ToolManager | scripts/globais/tool_manager.gd | Ferramenta equipada (`selected_tool`) |
| InventoryManager | scripts/globais/inventory_manager.gd | Itens (add/remove/get_count) |
| SaveGameManager | scripts/globais/save_game_manager.gd | Save/Load |
| GameDialogueManager | scripts/globais/game_dialogue_manager.gd | Ações disparadas por diálogos (`action_*`) |
| GameManager | scripts/globais/game_manager.gd | start_game / exit_game / menu |
| DayAndNightCycleManager | scripts/globais/day_and_night_cycle_manager.gd | Ciclo dia/noite |
| EventBus | scripts/globais/EventBus.gd | Sinais globais |
| AudioManager | scripts/globais/audio_manager.gd | Áudio (SFX/música/mute global) |
| NecromancerRegistry | scripts/globais/necromancer_registry.gd | Aparições do Necromante |
| SceneManager | scenes/scene_manager.gd | Troca de cenas/níveis |

## Ferramentas (DataTypes.Tools — scripts/globais/data_types.gd)
`None(0), AxeWood(1), TillGround(2), WaterCrops(3), PlantCorn(4), PlantTomato(5), Crossbow(6), BuildRock(7)`

## Sistemas principais (onde mexer)

### Plantio / Culturas
- `scenes/objects/plants/corn.gd` / `tomato.gd`: planta (regar no `on_hurt`, colheita).
- `scenes/objects/plants/growth_cycle_component.gd`: `GrowthCycleComponent` — `is_watered`, `starting_day`, crescimento por `time_tick_day`.
- `scenes/components/crop_cursor_component.gd`: **plantio automático** ao pisar em solo arado com semente (`_process` → `_auto_plant_if_on_tilled_soil`), `_plant_crop_at_cell`, `_has_crop_at_cell`, `_get_or_create_cropfields`.
- `scenes/components/field_cursor_component.gd`: arar/remover terra (TillGround + hit/remove_dirt).
- `scenes/Levels/tiled_soil.gd`: `TilledSoil` (TileMapLayer) — prompt de ação (sacola ou aviso).
- `is_watered = true` por padrão (pré-plantados crescem); plantados pelo jogador recebem `is_watered = false`.
- Milhos pré-plantados: `scenes/Levels/level_1.tscn` → `CropFields/Corn`, `Corn2`, `Corn3`.

### Diálogo
- Addon `addons/dialogue_manager/`; balloon custom: `dialogue/game_dialogue_balloon.tscn` + `dialogue/base_game_dialogue_ballon.gd`.
- Conversas em `dialogue/conversations/*.dialogue`. Ações: `do GameDialogueManager.action_xxx()`.
- `scenes/characters/guide/guide.gd`: Marlow — `_has_talked` controla re-conversa; `on_give_crop_seeds()` habilita `PlantCorn`.
- `GameDialogueManager` (`scripts/globais/game_dialogue_manager.gd`) emite sinais; sistemas conectam neles.

### Action Prompt (UI)
- `scenes/action_prompt.gd` / `.tscn`; instanciado em `scenes/ui/game_screen.tscn`.
- Sinais EventBus: `show_action_prompt(key,label)`, `hide_action_prompt`, `show_seed_bag`, `show_click_animation`, `show_action_warning(label)`.
- Modos: texto (tecla+ação), animação de clique, **sacola de sementes** (ícone estático `basic_plants.png` região 0,0,16,16), aviso de ferramenta errada.

### Áudio
- A ação `mute` (tecla M) é tratada pelo `GameManager` em qualquer tela.
- `AudioManager.toggle_mute()` alterna o mute do bus `Master`, cobrindo música, SFX e players de áudio das cenas.

### Barra de vida no mundo
- `scenes/components/world_health_bar.gd` / `.tscn`: `WorldHealthBar` (ProgressBar).
- API: `configure(cor, fundo, altura)` → `setup(max)` → `update_value(atual)`.
- ⚠️ Altura real vem de `size = Vector2(40, bar_height)` no `_create_styles()` — **não** de `custom_minimum_size` (só dica de container).
- Inimigos criam em código (`enemy.gd` `_create_health_bar`); fogueira adiciona na cena.

### Interação (proximidade)
- `scenes/components/interactable_component.gd`: `InteractableComponents` (Area2D) — sinais `interactable_activated` / `interactable_deactivated` (body_entered/exited).

### Níveis
- Level1: fazenda sem inimigos. Level2: Necromante + Mushrooms. Level3: novo inimigo.
- `SceneManager.DEV_START_LEVEL` escolhe nível inicial; teclas 1/2/3 trocam (dev).

## Collision Layers (bit value)
1 World · 2 Player · 4 Enemy/PlayerAttack · 8 HitComponent · 16 HurtComponent/Feed · 32 Collectable · 64 Animals · 128 Plants · 256 Interactable
