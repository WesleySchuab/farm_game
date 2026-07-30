Read [](file:///c%3A/Users/wesley/OneDrive%20-%20Project%20for%202/Documentos/fallen-realm-2/scenes/characters/player/player_hurt_component.gd)

Read [](file:///c%3A/Users/wesley/OneDrive%20-%20Project%20for%202/Documentos/fallen-realm-2/scenes/characters/enemy/enemy.tscn#180-180), lines 180 to 224

Read [](file:///c%3A/Users/wesley/OneDrive%20-%20Project%20for%202/Documentos/fallen-realm-2/scenes/components/hit_component.tscn)

2 tarefas pendentes criadas

Encontrei o bug! O problema está no cálculo da direção do knockback em player_hurt_component.gd.

**Análise:** Quando o inimigo está **abaixo** do player:
- `player - hit_component` = **UP** (do inimigo para o player)
- `aplicar_knockback` nega: `-UP = DOWN` → empurra **para baixo** (em direção ao inimigo) ❌

O correto é passar a direção **de onde o ataque veio** (do player em direção ao atacante), e aí a negação dentro de `aplicar_knockback` empurra para longe:

Iniciando: *Corrigir direção do knockback* (2/2)




```

```


Checked [](file:///c%3A/Users/wesley/OneDrive%20-%20Project%20for%202/Documentos/fallen-realm-2/scenes/characters/player/player_hurt_component.gd), no problems found

Concluído: *Corrigir direção do knockback* (2/2)

**Corrigido!** O problema estava na linha que calculava a direção do knockback.

### O que estava errado

```gdscript
# ANTES (ERRADO):
(player.global_position - hit_component.global_position).normalized()
```

Isso calculava a direção **do atacante → player**. Quando o `aplicar_knockback` negava essa direção (`-direction`), o resultado ficava errado para algumas direções.

**Exemplo:** inimigo atacando por **baixo**:
1. `player - hit_component` = **UP** (do chão em direção ao player)
2. `-UP × força` = **DOWN** → empurrava o player **para baixo** (em direção ao inimigo) ❌

### O que foi corrigido

```gdscript
# DEPOIS (CORRETO):
(hit_component.global_position - player.global_position).normalized()
```

Agora calcula a direção **de onde o ataque veio** (do player em direção ao atacante).

**Exemplo:** inimigo atacando por **baixo**:
1. `hit_component - player` = **DOWN** (direção de onde veio o golpe)
2. `-DOWN × força` = **UP** → empurra o player **para cima** (longe do inimigo) ✅

| Inimigo está | Antes (errado) | Depois (correto) |
|---|---|---|
| À direita | Empurrava direita ✅ | Empurra esquerda ✅ |
| À esquerda | Empurrava esquerda ✅ | Empurra direita ✅ |
| Acima | Empurrava cima ✅ | Empurra baixo ✅ |
| **Abaixo** | **Empurrava baixo** ❌ | **Empurra cima** ✅ |

Fez alterações.