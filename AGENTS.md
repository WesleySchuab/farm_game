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
- `scenes/Levels/tiled_soil.gd`: `TilledSoil` (TileMapLayer) — prompt da célula sob o player: sacola de sementes (célula vazia + ferramenta de plantio), `"Use o regador"` (cultura ainda sem água) e nada quando a célula não está arada, já tem cultura regada ou o regador está equipado.
- `is_watered = true` por padrão (pré-plantados crescem); plantados pelo jogador recebem `is_watered = false`.
- Milhos pré-plantados: `scenes/Levels/level_1.tscn` → `CropFields/Corn`, `Corn2`, `Corn3`.

### Diálogo
- Addon `addons/dialogue_manager/`; balloon custom: `dialogue/game_dialogue_balloon.tscn` + `dialogue/base_game_dialogue_ballon.gd`.
- Conversas em `dialogue/conversations/*.dialogue`. Ações: `do GameDialogueManager.action_xxx()`.
- `scenes/characters/guide/guide.gd`: Marlow — `_has_talked` controla re-conversa; `on_give_crop_seeds()` habilita `PlantCorn` **e** `WaterCrops` (regador liberado junto com a semente).
- `GameDialogueManager` (`scripts/globais/game_dialogue_manager.gd`) emite sinais; sistemas conectam neles.

### Action Prompt (UI)
- `scenes/action_prompt.gd` / `.tscn`; instanciado em `scenes/ui/game_screen.tscn`.
- Sinais EventBus: `show_action_prompt(key,label)`, `hide_action_prompt`, `show_seed_bag`, `show_click_animation`, `show_action_warning(label)`.
- Modos: texto (tecla+ação), animação de clique, **sacola de sementes** (ícone estático `basic_plants.png` região 0,0,16,16), aviso de ferramenta errada.

### Áudio
- A ação `mute` (tecla M) é tratada pelo `GameManager` em qualquer tela.
- `AudioManager.toggle_mute()` alterna o mute do bus `Master`, cobrindo música, SFX e players de áudio das cenas.
- Volume da música: bus `Music` via `AudioManager.set_music_volume_db(db)` / `set_music_volume_linear(0..1)` (persistido em `user://audio_settings.cfg`); o slider **Music** do menu usa essa API.
- Novos SFX entram no enum `AudioManager.SFX` + `SFX_PATHS` **sempre no final** (as cenas referenciam os IDs numéricos).
- Corvo: `CROW_CAW_HALLOWEEN` (surgimento do bando) e `CROW_CAW` (início do ataque).

### Barra de vida no mundo
- `scenes/components/world_health_bar.gd` / `.tscn`: `WorldHealthBar` (ProgressBar).
- API: `configure(cor, fundo, altura)` → `setup(max)` → `update_value(atual)`.
- ⚠️ Altura real vem de `size = Vector2(40, bar_height)` no `_create_styles()` — **não** de `custom_minimum_size` (só dica de container).
- Inimigos criam em código (`enemy.gd` `_create_health_bar`); fogueira adiciona na cena.

### Interação (proximidade)
- `scenes/components/interactable_component.gd`: `InteractableComponents` (Area2D) — sinais `interactable_activated` / `interactable_deactivated` (body_entered/exited).

### Inimigos com voo (Crow)
- `scenes/characters/enemy/crow.gd` (classe `Crow`): monta animações da cena (`fly_right`, `fly_down`, `fly_up`, `atack_right`, `atack_down`) e deriva os lados esquerdos por `flip_h` — não crie animação de "left".
- Estados dedicados em `crow_fly_state.gd` (sobrevoo: alterna pontos longe/perto do jogador) e `crow_attack_state.gd` (mergulho + hitbox), registrados na `StateMachine` como `Fly`/`Attack`.
- A arte olha para a direita, então `sprite_faces_right = true`; `hitbox_offset` define a posição do hitbox no ataque.
- Crow invocado pelo Necromante não abre portal próprio: `Enemy.skip_spawn_portal()` encerra o `PortalSpawnComponent` e usa o portal de quem invocou.
- ⚠️ A sprite sheet usa 128×128 por frame; linhas: `RIGHT` (3), `ATTACK DOWN` (4), `ATTACK RIGHT` (5).

### Fogueira e bandos de corvos
- `scenes/campfire/crow_flock_component.gd` (`CrowFlockComponent`) fica como filho da fogueira e gera ondas de **1 a 8 corvos** enquanto ela estiver apagada (máx. 8 vivos, primeira onda após `first_wave_delay` e novas a cada `respawn_delay`; surgem a 420–620 px do player).
- A fogueira publica `EventBus.campfire_state_changed(is_lit)` no início e ao acender/apagar; o componente escuta esse sinal e adiciona os corvos ao nível (irmão da fogueira), com `collision_mask = 0` e `attack_cooldown` sorteado (5–9 s).
- Ao reacender, `Crow.start_retreat()` faz os corvos fugirem e desaparecerem após `retreat_duration`.
- Sons: `AudioManager.SFX.CROW_CAW_HALLOWEEN` toca quando a onda surge; `CROW_CAW` toca no início de cada ataque (SFXComponent do `Crow`).

### Níveis
- Level1: fazenda sem inimigos fixos; corvos surgem em ondas enquanto a fogueira estiver apagada, e é o único nível com o aviso da fogueira do guia. Level2: Necromante apenas invoca MushMario (sem corvo no nível) e os avisos do guia ficam desativados. Level3: Necromante apenas invoca Crow (sem corvo fixo no nível) e os avisos do guia ficam desativados.
- `SceneManager.DEV_START_LEVEL` escolhe nível inicial; teclas 1/2/3 trocam (dev).

## Collision Layers (bit value)
1 World · 2 Player · 4 Enemy/PlayerAttack · 8 HitComponent · 16 HurtComponent/Feed · 32 Collectable · 64 Animals · 128 Plants · 256 Interactable
