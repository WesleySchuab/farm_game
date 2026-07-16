Ultima alteração foi na escala das arovores e design do maga_meu_background
alterações no esquema de sons, centralização em um script global, falta fazer isso para os animais
Feito a centralização do controle do som dos animais
Criado o inimigo

## Inimigo - Refatoração para Máquina de Estados ✅

**Data:** 15/07/2026

Refatorei completamente o sistema de inimigos para seguir o padrão do jogo:

### ✅ Implementado:
- **Máquina de Estados:** Idle → Chase → Attack (igual ao player)
- **3 Estados Funcionais:**
  - Idle: Parado esperando avistar player
  - Chase: Perseguindo player quando entra em chase_distance (150px)
  - Attack: Atacando quando entra em attack_distance (50px)
- **Animações Dinâmicas:**
  - mushroom_idle quando parado
  - mushroom_run quando perseguindo
  - mushroom_attack quando atacando
- **Sistema de Ataque:**
  - HitComponent para causar dano
  - Detecta colisão com player
  - Colisão desabilita entre ataques
- **Vida e Morte:**
  - max_health: 30
  - Função adicionar_vida() e morrer()
  - Reage à morte do player

### 📁 Arquivos Criados:
- `scenes/characters/enemy/enemy_state_machine.gd` (Máquina de Estados)
- `scenes/characters/enemy/enemy_idle_state.gd` (Estado Idle)
- `scenes/characters/enemy/enemy_chase_state.gd` (Estado Chase)
- `scenes/characters/enemy/enemy_attack_state.gd` (Estado Attack)
- `scenes/characters/enemy/enemy.gd` (Classe Enemy refatorada)
- `scenes/characters/enemy/ENEMY_SETUP.md` (Guia de configuração)

### 📋 Próximas Ações:
- [ ] Configurar StateMachine na cena (adicionar os 3 estados como filhos)
- [ ] Testar distâncias e comportamento
- [ ] Adicionar sons de ataque com AnimalSoundComponent
- [ ] Implementar XP/Drops ao inimigo morrer
- [ ] Criar variações do inimigo 