# Configuração do Inimigo - Fallen Realm 2

## ✅ Arquivos Criados/Atualizados

1. **enemy.gd** - Refatorado com máquina de estados
2. **enemy_state_machine.gd** - Máquina de estados (herda de NodeStateMachine)
3. **enemy_idle_state.gd** - Estado parado (animação: mushroom_idle)
4. **enemy_chase_state.gd** - Estado de perseguição (animação: mushroom_run)
5. **enemy_attack_state.gd** - Estado de ataque (animação: mushroom_attack)

---

## 🎮 Como Configurar a Cena

### Estrutura da Cena (enemy.tscn)

```
Enemy (CharacterBody2D) 
  ├── StateMachine (Node - enemy_state_machine.gd)
  │   ├── IdleState (Node - enemy_idle_state.gd)
  │   ├── ChaseState (Node - enemy_chase_state.gd)
  │   └── AttackState (Node - enemy_attack_state.gd)
  ├── AnimatedSprite2D
  ├── CollisionShape2D (física)
  └── HitComponent (Area2D)
      └── CollisionShape2D (colisão de ataque)
```

### Passos para Configurar

1. **Abra enemy.tscn no Godot**

2. **Adicione os Estados à Máquina de Estados:**
   - Seletor: `Node Enemy > StateMachine`
   - Adicione 3 filhos (Nós) com os nomes:
     - `Idle` → Script: `enemy_idle_state.gd`
     - `Chase` → Script: `enemy_chase_state.gd`
     - `Attack` → Script: `enemy_attack_state.gd`

3. **Configure o Estado Inicial:**
   - Seletor: `Node Enemy > StateMachine`
   - Inspector → `Initial Node State`: Selecione `Idle`

4. **Conecte o HitComponent (para atacar):**
   - Seletor: `Node Enemy > HitComponent`
   - Inspector:
     - `current_tool`: Nenhuma (deixe como None ou crie um enum específico)
     - `hit_damage`: 10 (ajuste conforme necessário)

5. **Configure o CollisionShape2D (dentro de HitComponent):**
   - Posição: Ajuste para cobrir a área de ataque
   - Shape: RectangleShape2D (já criada na cena)

---

## ⚙️ Parâmetros Exportáveis do Enemy

| Parâmetro | Padrão | Descrição |
|-----------|--------|-----------|
| `chase_speed` | 40.0 | Velocidade de perseguição (px/s) |
| `max_health` | 30.0 | Vida máxima do inimigo |
| `current_health` | 30.0 | Vida atual (inicia cheia) |
| `chase_distance` | 150.0 | Distância para começar a perseguir |
| `attack_distance` | 50.0 | Distância mínima para atacar |

---

## 🎬 Animações Configuradas

A cena já possui as animações:
- `mushroom_idle` - Inimigo parado
- `mushroom_run` - Inimigo correndo
- `mushroom_attack` - Inimigo atacando

Se precisar mudar os nomes, atualize nos scripts dos estados.

---

## 📊 Fluxo de Estados

```
Idle
  └─→ Chase (quando player entra em chase_distance)

Chase
  ├─→ Attack (quando player entra em attack_distance)
  └─→ Idle (quando player sai de chase_distance * 1.5)

Attack
  ├─→ Chase (quando player sai de attack_distance)
  └─→ Chase (quando player sai de chase_distance)
```

---

## 🔧 Sistema de Dano

1. **Quando o inimigo ataca:**
   - HitComponent ativa collisionShape
   - Detecta colisão com HurtComponent do player
   - Causa dano configurável em `hit_damage`

2. **Quando o player ataca o inimigo:**
   - Player usa ferramenta (HitComponent)
   - Detecta colisão com `HurtComponent` do inimigo
   - Inimigo perde vida via `adicionar_vida(-dano)`

---

## 🛠️ Próximos Passos

- [ ] Testar detecção de distância
- [ ] Ajustar valores de chase_distance e attack_distance
- [ ] Criar mais tipos de inimigos (clone do sistema)
- [ ] Adicionar sistema de XP/Drops ao morrer
- [ ] Adicionar sons de ataque do inimigo (AnimalSoundComponent)
- [ ] Implementar knockback ao receber dano

---

## ⚠️ Dependências

- EventBus (para sinal de morte do player)
- NodeStateMachine (base dos estados)
- HitComponent (para ataque)
- AnimatedSprite2D (com animações criadas)
- CollisionShape2D (física + detecção)

---

**Criado em:** 15/07/2026  
**Padrão:** Segue arquitetura do Player com máquina de estados
