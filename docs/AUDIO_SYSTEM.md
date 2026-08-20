# 🔊 Sistema de Áudio (AudioManager)

Centralização total de áudio do jogo. Todo som deve passar pelo autoload **AudioManager**.

## Arquivo principal

- `scripts/globais/audio_manager.gd` (autoload `AudioManager`)

## Estrutura

```
AudioManager
├── enum SFX              → IDs numéricos dos sons
├── SFX_PATHS             → dicionário {ID: caminho do arquivo}
├── SFX_VARIATIONS        → grupos de sons com variação (passos, galinha)
├── enum MUSIC            → IDs numéricos das músicas
├── MUSIC_PATHS           → dicionário {ID: caminho do arquivo}
├── music_player          → AudioStreamPlayer (bus "Music")
├── sfx_player            → AudioStreamPlayer (bus "SFX", sons globais/UI)
└── sfx_pool_2d           → 16 AudioStreamPlayer2D (sons espaciais no mundo)
```

## Como adicionar um som novo (3 passos)

1. **Registrar no enum `SFX`** (adicione no fim para não quebrar os IDs existentes):

```gdscript
enum SFX {
	# ... existentes ...
	PICKAXE_HIT,
	AXE_HIT,
}
```

2. **Mapear o caminho em `SFX_PATHS`**:

```gdscript
const SFX_PATHS := {
	# ... existentes ...
	SFX.PICKAXE_HIT: "res://game/assets/audio/music/picareta.mp3",
	SFX.AXE_HIT: "res://game/assets/audio/music/machado.mp3",
}
```

3. **Tocar** onde precisar:

```gdscript
AudioManager.play_sfx_at(AudioManager.SFX.AXE_HIT, global_position, -4)
```

## API principal

| Função | Uso |
|---|---|
| `play_sfx(id, vol_db)` | Som global (UI/menu) |
| `play_sfx_at(id, pos, vol_db)` | Som espacial na posição do mundo (recomendado) |
| `play_sfx_pitched(id, pitch_range, vol_db)` | Som global com pitch aleatório |
| `play_sfx_varied_at(id, pos, pitch_range, vol_db)` | Espacial + variação de sample |
| `play_music(id, vol_db, pitch)` | Toca música no bus Music |
| `stop_music()` | Para a música atual |

## Como adicionar uma música nova (3 passos)

1. **Registrar no enum `MUSIC`**:

```gdscript
enum MUSIC {
	ON_THE_FARM,
	OPENING,
}
```

2. **Mapear o caminho em `MUSIC_PATHS`**:

```gdscript
const MUSIC_PATHS := {
	MUSIC.ON_THE_FARM: "res://game/assets/audio/music/On the Farm.ogg",
	MUSIC.OPENING: "res://game/assets/audio/music/opening_soundtrack.mp3",
}
```

3. **Tocar** onde precisar:

```gdscript
AudioManager.play_music(AudioManager.MUSIC.ON_THE_FARM)
```

## Controle de volume

O 3º argumento `vol_db` é o volume em **decibéis**:

| Valor | Efeito |
|---|---|
| `0.0` | Neutro (padrão) |
| `-6.0` | ~metade da intensidade |
| `-12.0` | Bem baixo |
| `-20.0` | Quase inaudível |
| `+3.0` | Um pouco mais alto |

Volume global por categoria: painel **Audio** no editor, ou `audio/game_audio_bus_layout.tres`:

- Bus **SFX**: `-2.31 dB` (efeitos sonoros)
- Bus **Music**: `-0.92 dB` (músicas)

## SFXComponent (componente reutilizável)

`scenes/components/sfx_component.gd` — anexe a qualquer Node2D e configure na cena:

- `attack_sfx`, `summon_sfx`, `footstep_sfx` → IDs do enum SFX
- `volume_db` → volume do componente
- Sinais: `attack_triggered`, `summon_triggered`, `footstep_triggered`

Exemplo no player (`player.tscn`): `attack_sfx = 3` (ARROW_SHOT).

## AnimalSoundComponent (sons de animais)

`scenes/components/animal_sound_component.gd` — timer + chance para sons de animais:

- `animal_sfx` → ID do enum SFX (ex: `AudioManager.SFX.COW_MOO`)
- `use_variation` → `true` usa variação de samples (galinha: cluck 1/2/3)
- `sound_interval` / `sound_chance` / `volume_db` → configuração do timer

Anexado em código nos animais (`chicken.gd`, `cow.gd`) via `AnimalSoundComponent.new()`.

## Onde ficam os arquivos

- SFX: `game/assets/audio/sfx/*.ogg`
- Música: `game/assets/audio/music/*.ogg|.mp3`
- ⚠️ `picareta.mp3` e `machado.mp3` estão na pasta `music/` (sons de ferramenta, mas o caminho usado no enum está correto)

## Sons de ferramenta (picareta/machado)

Disparados no `on_hurt` do objeto atingido:

- `rock.gd` → `AudioManager.SFX.PICKAXE_HIT`
- `small_tree.gd` / `large_tree.gd` → `AudioManager.SFX.AXE_HIT`

Só tocam quando o golpe realmente acerta (sinal `hurt` do HurtComponent, que valida a ferramenta).

## Debug

- Prints do AudioManager: `🎵 [AudioManager] ...`
- Prints do SFXComponent: `🔊 [SFXComponent] ...`
