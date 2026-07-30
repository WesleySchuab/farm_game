# Sistema de Knockback — Documentação Completa

> **Propósito:** Quando o player recebe dano de um inimigo, ele é empurrado para trás (direção oposta ao atacante) com um impulso que desacelera gradualmente.

---

## 1. Visão Geral da Arquitetura

O knockback envolve **4 arquivos** que trabalham em conjunto:

| Arquivo | Função |
|---|---|
| `scenes/characters/player/player.gd` | Armazena estado do knockback, aplica o movimento físico |
| `scenes/characters/player/player_hurt_component.gd` | Detecta o ataque e **dispara** o knockback |
| `scenes/characters/player/walk_state.gd` | Bloqueia movimento do jogador durante knockback |
| `scenes/characters/player/idle_state.gd` | Bloqueia transições de estado durante knockback |

### Fluxo de Execução

```
Inimigo ataca (HitComponent)
       ↓
PlayerHurtComponent._on_area_entered()
       ↓
1. Aplica dano: player.adicionar_vida(-hit_damage)
2. Calcula direção: (hit_component - player).normalized()
3. Dispara knockback: player.aplicar_knockback(direction)
       ↓
Player._physics_process()  (roda ANTES da state machine)
       ↓
Se _knockback_timer > 0:
  - velocity = knockback_velocity
  - move_and_slide()
  - decrementa timer
  - desacelera knockback_velocity
       ↓
State Machine._physics_process()  (roda DEPOIS)
       ↓
walk_state: detecta knockback_velocity != ZERO → retorna cedo (idle animation)
idle_state: detecta knockback_velocity != ZERO → não transiciona
```

---

## 2. player.gd — O Coração do Knockback

### Variáveis

```gdscript
# (pública) Velocidade atual do knockback — usada por outros scripts para detectar se está ativo
var knockback_velocity: Vector2 = Vector2.ZERO

# (export) Força do impulso em pixels/segundo. Ajustável no Inspector.
@export var knockback_force: float = 400.0

# (export) Duração do knockback em segundos. Ajustável no Inspector.
@export var knockback_duration: float = 0.0

# (privada) Timer interno em segundos. Controla por quanto tempo o knockback dura.
var _knockback_timer: float = 0.0
```

### Método: `aplicar_knockback(direction, force = -1.0)`

```gdscript
func aplicar_knockback(direction: Vector2, force: float = -1.0) -> void:
    if is_dead:
        return

    # Se force não foi passado, usa knockback_force
    var knockback_strength = force if force >= 0 else knockback_force

    # direction = direção DE ONDE veio o ataque (ex: Vector2.RIGHT = ataque veio da direita)
    # -direction = direção oposta (empurra para longe)
    knockback_velocity = -direction * knockback_strength
    _knockback_timer = knockback_duration
```

### Processo Físico: `_physics_process(delta)`

```gdscript
func _physics_process(_delta: float) -> void:
    if is_dead:
        return

    if _knockback_timer > 0.0:
        velocity = knockback_velocity      # Define a velocidade de knockback
        move_and_slide()                    # Aplica o movimento
        _knockback_timer -= _delta          # Reduz o timer
        # Desaceleração gradual (move_toward suaviza até Vector2.ZERO)
        knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_force * _delta * 2.0)
    else:
        knockback_velocity = Vector2.ZERO   # Reseta quando acaba
```

> ⚠️ **IMPORTANTE:** O `_physics_process` do `player.gd` roda **ANTES** do `_physics_process` da State Machine (ordem padrão do Godot: pai antes dos filhos). Por isso o knockback consegue aplicar `move_and_slide()` primeiro, e os estados só precisam verificar se `knockback_velocity != ZERO` para não sobrescrever.

---

## 3. player_hurt_component.gd — O Gatilho

### Localização: `scenes/characters/player/player_hurt_component.gd`

Quando uma área (HitComponent do inimigo) colide com o PlayerHurtComponent:

```gdscript
func _on_area_entered(area: Area2D) -> void:
    var hit_component = area as HitComponent
    if hit_component == null:
        return

    if player:
        # 1. Aplica dano
        player.adicionar_vida(-hit_component.hit_damage)
        hurt.emit(hit_component.hit_damage)

        # 2. Calcula direção do knockback
        #    hit_component.global_position = posição do atacante
        #    player.global_position        = posição do player
        #    (hit_component - player)      = vetor do player em direção ao atacante
        var attack_direction: Vector2 = (hit_component.global_position - player.global_position).normalized()
        
        # 3. Dispara knockback
        player.aplicar_knockback(attack_direction)
```

### Cálculo da Direção — Detalhamento

```
Fórmula: attack_direction = (hit_component - player).normalized()

Exemplo: inimigo à DIREITA do player
  hit_component.x > player.x
  (hit_component - player) = (+diff, 0) → RIGHT
  aplicar_knockback(RIGHT) → knockback_velocity = -RIGHT = LEFT
  Player empurrado para ESQUERDA ✅

Exemplo: inimigo ABAIXO do player
  hit_component.y > player.y
  (hit_component - player) = (0, +diff) → DOWN
  aplicar_knockback(DOWN) → knockback_velocity = -DOWN = UP
  Player empurrado para CIMA ✅

Exemplo: inimigo à ESQUERDA do player
  hit_component.x < player.x
  (hit_component - player) = (-diff, 0) → LEFT
  aplicar_knockback(LEFT) → knockback_velocity = -LEFT = RIGHT
  Player empurrado para DIREITA ✅

Exemplo: inimigo ACIMA do player
  hit_component.y < player.y
  (hit_component - player) = (0, -diff) → UP
  aplicar_knockback(UP) → knockback_velocity = -UP = DOWN
  Player empurrado para BAIXO ✅
```

> **BUG ANTERIOR:** Antes usava `(player - hit_component)` que dava a direção do atacante → player. A negação em `aplicar_knockback` invertia, e o resultado era: inimigo abaixo → empurrava para BAIXO (direção errada). A correção foi inverter a subtração.

---

## 4. walk_state.gd — Bloqueio de Movimento

### Localização: `scenes/characters/player/walk_state.gd`

### `_on_physics_process` — Early return durante knockback

```gdscript
func _on_physics_process(_delta: float) -> void:
    if not controle_de_animacao_ativo: 
        return

    # ⏸️ KNOCKBACK ATIVO — não processa movimento, mostra idle
    if player.knockback_velocity != Vector2.ZERO:
        # Mostra animação idle ou crossbow_idle dependendo da ferramenta
        if player.current_tool == DataTypes.Tools.Crossbow:
            var anim: String = "crossbow_front_idle"
            match player.player_direction:
                Vector2.UP: anim = "crossbow_back_idle"
                Vector2.DOWN: anim = "crossbow_front_idle"
                Vector2.LEFT: anim = "crossbow_left_idle"
                Vector2.RIGHT: anim = "crossbow_right_idle"
            if animated_sprite_2d.animation != anim:
                animated_sprite_2d.play(anim)
        else:
            var anim: String = "idle_front"
            match player.player_direction:
                Vector2.UP: anim = "idle_back"
                Vector2.DOWN: anim = "idle_front"
                Vector2.LEFT: anim = "idle_left"
                Vector2.RIGHT: anim = "idle_right"
            if animated_sprite_2d.animation != anim:
                animated_sprite_2d.play(anim)
        return  # ← Sai sem chamar move_and_slide()

    # ... movimento normal (direction, wants_to_run, animações...) ...
    player.velocity = direction * current_speed
    player.move_and_slide()
```

### `_on_next_transitions` — Não transiciona durante knockback

```gdscript
func _on_next_transitions() -> void:
    # ⏸️ KNOCKBACK ATIVO — não muda de estado
    if player.knockback_velocity != Vector2.ZERO:
        return

    if !GameInputEvents.movement_input():
        transition.emit("idle")
    # ... outras transições ...
```

---

## 5. idle_state.gd — Bloqueio de Transições

### Localização: `scenes/characters/player/idle_state.gd`

```gdscript
func _on_next_transitions() -> void:
    # ⏸️ KNOCKBACK ATIVO — não transiciona para walk nem ferramentas
    if player.knockback_velocity != Vector2.ZERO:
        return

    GameInputEvents.movement_input()
    if GameInputEvents.is_moviment_input():
        transition.emit("walk")
    # ... outras transições (Chopping, Tilling, Watering, Crossbow) ...
```

> Isso impede que o player entre em estado de caminhada ou ferramenta enquanto está sendo empurrado.

---

## 6. enemy_attack_state.gd — Timing do Hit

### Localização: `scenes/characters/enemy/enemy_attack_state.gd`

> **Nota:** Este arquivo também foi modificado para que o hitbox do inimigo só apareça no frame correto da animação. Relacionado ao knockback porque define QUANDO o dano (e consequentemente o knockback) ocorre.

```gdscript
# Frame da animação em que o hit é ativado (0-indexed)
@export var attack_hit_frame: int = 6

func _ready() -> void:
    # ... outras inicializações ...
    animated_sprite_2d.frame_changed.connect(_on_animation_frame_changed)

func _on_enter() -> void:
    animated_sprite_2d.play("mushroom_attack_right")
    hit_component_collision_shape.disabled = true  # Começa desabilitado!

func _on_animation_frame_changed() -> void:
    if animated_sprite_2d.animation == "mushroom_attack_right" \
        and animated_sprite_2d.frame >= attack_hit_frame \
        and hit_component_collision_shape.disabled:
        hit_component_collision_shape.disabled = false
```

**Animação `mushroom_attack_right`:**
- 9 frames (0 a 8), speed 4.0, sem loop
- Frame 6 ≈ 75% da animação (golpe final)

---

## 7. Configuração e Ajustes

### No Inspector do Player (player.gd)

| Propriedade | Tipo | Padrão | Descrição |
|---|---|---|---|
| `knockback_force` | float | 400.0 | Força do impulso (px/s). Maior = mais longe. |
| `knockback_duration` | float | 0.2 | Duração em segundos. Maior = mais tempo "atordoado". |

### Valores Recomendados para Teste

```gdscript
# Knockback suave
knockback_force = 150.0
knockback_duration = 0.15

# Knockback padrão (atual)
knockback_force = 400.0
knockback_duration = 0.2

# Knockback explosivo (lança longe)
knockback_force = 600.0
knockback_duration = 0.3
```

---

## 8. Resumo — Checklist para Reimplementação

Caso precise refazer do zero após o reset:

1. **player.gd**
   - [ ] Adicionar `knockback_velocity: Vector2`
   - [ ] Adicionar `@export var knockback_force: float = 400.0`
   - [ ] Adicionar `@export var knockback_duration: float = 0.2`
   - [ ] Adicionar `_knockback_timer: float`
   - [ ] Adicionar método `aplicar_knockback(direction, force = -1.0)`
   - [ ] Adicionar `_physics_process(delta)` com a lógica de knockback

2. **player_hurt_component.gd**
   - [ ] Em `_on_area_entered`, após aplicar dano:
     - `var attack_direction = (hit_component.global_position - player.global_position).normalized()`
     - `player.aplicar_knockback(attack_direction)`

3. **walk_state.gd**
   - [ ] Em `_on_physics_process`: verificar `player.knockback_velocity != Vector2.ZERO` → mostrar idle + return
   - [ ] Em `_on_next_transitions`: verificar `player.knockback_velocity != Vector2.ZERO` → return

4. **idle_state.gd**
   - [ ] Em `_on_next_transitions`: verificar `player.knockback_velocity != Vector2.ZERO` → return

---

## 9. Arquivos Envolvidos (Caminhos Completos)

```
scenes/characters/player/player.gd
scenes/characters/player/player_hurt_component.gd
scenes/characters/player/walk_state.gd
scenes/characters/player/idle_state.gd
scenes/characters/enemy/enemy_attack_state.gd         (timing do hit)
scenes/components/hit_component.gd                     (current_tool)
scenes/objects/weapons/arrow.gd                        (current_tool = Crossbow)
```
