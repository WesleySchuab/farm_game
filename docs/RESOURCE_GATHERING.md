# 🪨 Coleta de Recursos (Rochas, Árvores, Plantas e Animais)

Documenta como o jogador coleta itens do mundo (madeira, pedra, plantações, animais).

## Fluxo completo

```
Player ataca (HitComponent)
   ↓  area_entered
HurtComponent valida ferramenta (tool == current_tool)
   ↓  sinal hurt(damage)
Objeto aplica dano (DamageComponent.apply_damage)
   ↓  max_damage atingido
Objeto spawna o drop + queue_free
   ↓
Drop (CollectableComponent, Area2D) detecta o Player
   ↓  _on_body_entered
InventoryManager.add_collectable(nome)
   ↓
Drop é removido da cena
```

## Componentes envolvidos

| Componente | Tipo | Layers | Papel |
|---|---|---|---|
| `HitComponent` | Area2D | layer 8, mask 16 | Ataque do player |
| `HurtComponent` | Area2D | layer 16, mask 8 | Recebe o ataque e valida a ferramenta |
| `DamageComponent` | Node2D | — | Acumula dano até `max_damage` |
| `CollectableComponent` | Area2D | layer 32, mask 2 | Coleta automática ao encostar |

## Objetos quebráveis e seus drops

| Objeto | Cena | Ferramenta (`tool`) | `max_damage` | Drop | Coletável |
|---|---|---|---|---|---|
| Rocha | `rocks/rock.tscn` | 1 (AxeWood) | 4 | `rocks/stone.tscn` | `"stone"` |
| Rocha média | `rocks/mediun_rock.tscn` | 1 (AxeWood) | 4 | `rocks/stone.tscn` | `"stone"` |
| Árvore pequena | `tree/small_tree.tscn` | 1 (AxeWood) | 2 | `tree/log.tscn` | `"wood"` |
| Árvore grande | `tree/large_tree.tscn` | 1 (AxeWood) | 3 | `tree/log.tscn` | `"wood"` |

> ⚠️ **Não existe ferramenta "picareta"** no enum `DataTypes.Tools`. Rochas e árvores usam a mesma ferramenta (`AxeWood = 1`). O som é que diferencia: picareta na rocha, machado na árvore.

## Ferramentas (DataTypes.Tools)

`None(0), AxeWood(1), TillGround(2), WaterCrops(3), PlantCorn(4), PlantTomato(5), Crossbow(6)`

## Coletáveis existentes

- `"wood"` (log.tscn)
- `"stone"` (stone.tscn)
- `"egg"` (egg.tscn)
- `"milk"` (milk.tscn)
- `"corn"` (corn_harvest.tscn)
- `"tomato"` (tomato_harvest.tscn)

Animais (`cow`, `chicken`, `milk`, `egg`): além de ir para o inventário, curam o player via `body.adicionar_vida(...)`.

## Como adicionar um novo recurso quebrável

1. Crie a cena do objeto com:
   - `HurtComponent` (defina `tool` no .tscn)
   - `DamageComponent` (defina `max_damage`)
2. No script do objeto, conecte `hurt_component.hurt` → `on_hurt` e `damage_component.max_damaged_reached` → spawn do drop.
3. Crie a cena do drop com `CollectableComponent` e defina `collectable_name`.
4. (Opcional) Toque o som no `on_hurt`:
   ```gdscript
   AudioManager.play_sfx_at(AudioManager.SFX.AXE_HIT, global_position, -4)
   ```

## Armadilhas comuns

- **Tool mismatch**: se o `tool` do HurtComponent não bater com a ferramenta do HitComponent, o golpe é ignorado (era o bug "não consigo coletar rocha").
- **Layer/Mask**: HurtComponent (layer 16, mask 8) deve enxergar o HitComponent (layer 8).
- **Drop sobre o player**: o `CollectableComponent` detecta o corpo do player (layer 2) e coleta sozinho ao encostar.
