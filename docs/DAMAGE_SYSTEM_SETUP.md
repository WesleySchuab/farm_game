
### 2. Sistema de Debug Adicionado 🐛

Prints em:
- `hit_component.gd` - Detecta todas as colisões
- `player_hurt_component.gd` - Recebe dano
- `enemy_attack_state.gd` - Estado de ataque
- `enemy_chase_state.gd` - Transição para ataque
- `enemy.gd` - Inicialização

---

## 📋 Próximos Passos - Configurar na Cena

### Passo 1: Adicionar PlayerHurtComponent ao Player

1. Abra `scenes/characters/player/player.tscn`
2. Selecione o nó **Player** (raiz)
3. Adicione um filho do tipo **Area2D**
4. Renomeie para **PlayerHurtComponent**
5. Anexe script: `player_hurt_component.gd`
6. Configure:
   - **Position**: Ajuste para cobrir o player (ex: 0, -20)
   - **Shape**: Adicione **CircleShape2D** ou **RectangleShape2D**
   - Tamanho: Aproximadamente do tamanho do player

### Passo 2: Configurar Collision Layers/Masks

**Para o Player (PlayerHurtComponent):**
- Layer: **2** (ou qualquer layer do player)
- Mask: **3** (para detectar colisão do inimigo)

**Para o Enemy (HitComponent):**
- Layer: **3** (ou qualquer layer de ataque)
- Mask: **2** (para detectar colisão do player)

---

## 📊 Fluxo de Dano

```
Inimigo (Attack State)
  ↓
t=0.0s   → Entra no estado Attack + toca animação "attack"
            (wind-up: inimigo se prepara pra bater)
            🚫 Hitbox DESATIVADO
  ↓
t=2.0s   → Hitbox ATIVADO (hitbox_enable_delay = 2.0)
            ⚡ Frame de impacto: colisão acontece AQUI
            👁️ Player JÁ vê a animação de ataque
  ↓
HitComponent ativado
  ↓
PlayerHurtComponent detecta colisão
  ↓
player_hurt_component._on_area_entered()
  ↓
player.adicionar_vida(-dano)
  ↓
EventBus.player_health_changed.emit()
  ↓
UI atualiza vida
  ↓
t=2.5s   → Animação termina → volta para Chase
```

---

## 🔍 Como Debugar

Execute o jogo e procure pelos prints:

``` 
👹 [ENEMY] Inimigo inicializado - Chase Distance: 150 | Attack Distance: 35
🟡 [CHASE STATE] Player em zona de ataque! Distância: 30.00 | Attack Distance: 35 → Transitando para ATTACK
🔴 [ATTACK STATE] Animação 'attack' iniciada! Hitbox será ativada em 2.00s
🔴 [ATTACK STATE] Hitbox ATIVADA no frame de impacto! (t=2.00s)
⚔️ [HIT COMPONENT] Colisão detectada com: PlayerHurtComponent
🛡️ [PLAYER HURT] Detectada colisão com: HitComponent
✅ [PLAYER HURT] HitComponent detectado! Dano: 10
💥 [PLAYER HURT] Player recebeu 10 de dano! Vida: 90
🔴 [ATTACK STATE] Animação terminou! Voltando para Chase
```

Se não ver esses prints, significa:
- ❌ Collision layers/masks erradas
- ❌ PlayerHurtComponent não adicionado
- ❌ Shape não configurado corretamente
- ❌ `hitbox_enable_delay` muito alto (hitbox não ativa a tempo)

> 💡 **Timing:** O hitbox só ativa após `hitbox_enable_delay` (padrão: 2.0s) do início da animação.
> Ajuste esse valor no nó **Attack** do inimigo para sincronizar com o frame de impacto.

---

## 🎮 Configuração Rápida (Exemplo)

```
Player (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D (física)
├── HitComponent (atacar árvores)
│   └── CollisionShape2D
└── PlayerHurtComponent (receber dano) ← ADICIONAR AQUI
    └── CircleShape2D (raio ~30)
```

---

## 💡 Alternativa - Se Não Funcionar

Se as colisões não funcionarem mesmo com layers/masks corretas:

1. Verifique se `monitoring = true` em ambos Area2D
2. Verifique se `monitorable = true` em ambos Area2D
3. Teste com shapes muito maiores para descartar problema de tamanho
4. Olhe o console para prints de erro

---

**Criado:** 16/07/2026
