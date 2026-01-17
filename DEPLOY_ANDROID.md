# 📱 Guia de Deploy para Android - Fallen Realm 2

## Pré-requisitos

### 1. Instalar Android SDK
- Baixe o Android Studio: https://developer.android.com/studio
- Durante a instalação, certifique-se de instalar:
  - Android SDK
  - Android SDK Platform-Tools
  - Android SDK Build-Tools

### 2. Configurar Godot para Android

1. **Abra o Godot Editor**

2. **Vá em Editor → Configurações do Editor → Export → Android**
   - **Android SDK Path**: Normalmente em `C:\Users\SEU_USUARIO\AppData\Local\Android\Sdk`
   - **Debug Keystore**: O Godot pode gerar automaticamente
   
3. **Instalar Templates de Export**
   - Vá em **Editor → Gerenciar Templates de Export**
   - Clique em **Baixar e Instalar**
   - Aguarde o download completar

## Configurar Export do Projeto

### 1. Abrir Configurações de Export
- Vá em **Projeto → Exportar**
- Clique em **Adicionar** e selecione **Android**

### 2. Configurações Essenciais

#### Aba "Options"
- **Nome do Pacote**: `com.seu_nome.fallen_realm2`
  - Use apenas letras minúsculas, números e pontos
  - Formato: `com.empresa.nomejogo`
- **Versão/Code**: 1
- **Versão/Name**: "1.0"
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (mais recente)

#### Aba "Resources"
- Deixe padrão ou ajuste conforme necessário

#### Aba "Screen"
- **Orientation**: 
  - `Landscape` (horizontal) - recomendado para seu jogo
  - ou `Portrait` (vertical)

### 3. Permissões (se necessário)
- Na aba **Permissions**, ative apenas as que você precisa
- Para jogos básicos, geralmente não precisa de nenhuma

## Exportar e Instalar no Celular

### Método 1: Deploy Direto (Recomendado para Testes)

1. **Habilitar Depuração USB no Celular**
   - Vá em **Configurações → Sobre o telefone**
   - Toque 7 vezes em "Número da versão" para ativar modo desenvolvedor
   - Volte e vá em **Configurações → Opções do desenvolvedor**
   - Ative **Depuração USB**

2. **Conectar o Celular ao PC via USB**
   - Conecte o cabo USB
   - No celular, autorize a depuração USB quando solicitado

3. **Verificar Conexão**
   - Abra um terminal e execute:
   ```powershell
   cd C:\Users\wesley\AppData\Local\Android\Sdk\platform-tools
   .\adb devices
   ```
   - Seu dispositivo deve aparecer na lista

4. **Deploy com Um Clique no Godot**
   - No canto superior direito do editor, clique na seta ao lado do botão Play
   - Selecione **Deploy Remoto**
   - Selecione **Android**
   - O jogo será instalado e executado automaticamente no celular

### Método 2: Exportar APK

1. **Na janela de Export**
   - Clique em **Exportar Projeto**
   - Escolha um local e nome: `fallen_realm_2.apk`
   - Marque **Export With Debug** (para testes)
   - Clique em **Salvar**

2. **Instalar o APK no Celular**
   
   **Opção A - Via ADB:**
   ```powershell
   cd C:\Users\wesley\AppData\Local\Android\Sdk\platform-tools
   .\adb install caminho\para\fallen_realm_2.apk
   ```
   
   **Opção B - Manualmente:**
   - Transfira o APK para o celular (por cabo, Bluetooth, Drive, etc)
   - No celular, abra o arquivo APK
   - Permita a instalação de fontes desconhecidas quando solicitado
   - Instale o app

## Exportar APK de Release (Para Distribuição)

### 1. Criar uma Keystore
```powershell
cd C:\Users\wesley\AppData\Local\Android\Sdk\build-tools\<versao>
.\keytool -genkey -v -keystore fallen_realm_release.keystore -alias fallen_realm_key -keyalg RSA -keysize 2048 -validity 10000
```

### 2. Configurar no Godot
- Em **Projeto → Exportar → Android**
- Na aba **Keystore**:
  - **Release**: Caminho para sua keystore
  - **Release User**: alias que você definiu
  - **Release Password**: senha da keystore

### 3. Exportar
- Desmarque **Export With Debug**
- Exporte o APK final

## Otimizações para Mobile

### 1. Resolução
Seu projeto já está otimizado com:
- Viewport: 640x360
- Window override: 1280x720
- Stretch mode: viewport
- Scale mode: integer

### 2. Performance
```gdscript
# Adicione estas configurações se necessário:
# project.godot
[rendering]
renderer/rendering_method="mobile"
textures/canvas_textures/default_texture_filter=0
2d/options/use_nvidia_rect_flicker_workaround=true
```

### 3. Controles Touch
Considere adicionar:
- Botões virtuais na tela
- Joystick virtual
- Gestos de toque

## Troubleshooting

### Erro: "adb not found"
- Adicione o ADB ao PATH do Windows:
  - Variáveis de Ambiente → Path → Adicionar: `C:\Users\wesley\AppData\Local\Android\Sdk\platform-tools`

### Erro: "No Android devices found"
- Verifique se depuração USB está ativada
- Tente outro cabo USB
- Reinstale os drivers USB do dispositivo

### APK não instala
- Verifique se "Instalar apps desconhecidos" está permitido
- Tente desinstalar versões antigas primeiro
- Verifique se há espaço suficiente no celular

### Jogo está lento
- Reduza a resolução do viewport
- Simplifique shaders e efeitos
- Use texturas comprimidas
- Ative o profiler do Godot para identificar gargalos

## Testes em Diferentes Dispositivos

Teste em:
- Diferentes tamanhos de tela
- Diferentes versões do Android
- Dispositivos com diferentes capacidades de hardware

## Próximos Passos

1. **Google Play Store**
   - Crie uma conta de desenvolvedor (taxa única de $25)
   - Prepare capturas de tela e descrição
   - Configure a listagem
   - Faça upload do APK/AAB

2. **Considere AAB (Android App Bundle)**
   - Formato recomendado pela Google Play
   - Tamanho de download menor
   - Otimização automática por dispositivo

---

## Comandos Rápidos

```powershell
# Verificar dispositivos conectados
adb devices

# Instalar APK
adb install fallen_realm_2.apk

# Desinstalar app
adb uninstall com.seu_nome.fallen_realm2

# Ver logs do app
adb logcat | Select-String "godot"

# Fazer screenshot
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Gravar tela (Android 4.4+)
adb shell screenrecord /sdcard/demo.mp4
# Ctrl+C para parar
adb pull /sdcard/demo.mp4
```

Boa sorte com o deploy! 🎮
