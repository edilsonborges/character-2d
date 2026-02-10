# Character 2D — Documentacao Tecnica

## 1. Visao Geral

**Character 2D** e um projeto multiplataforma de animacao 2D procedural com tematica de festa de aniversario. O projeto possui duas implementacoes independentes que compartilham o mesmo conceito visual:

| Plataforma | Tecnologia | Diretorio |
|---|---|---|
| macOS Desktop | Love2D (Lua) | `/` (raiz) |
| Web (browser) | love.js (Emscripten) | `/web/` + CI build |
| iOS (iPhone nativo) | SwiftUI + Canvas | `/love2d-app/` |

**Repositorio:** `github.com/edilsonborges/character-2d`

---

## 2. Arquitetura do Projeto

```
character-2d/
├── main.lua                  # Jogo Love2D (desktop + web)
├── conf.lua                  # Configuracao Love2D (340x250)
├── Makefile                  # Comandos de build local
├── web/
│   └── index.html            # Shell HTML para build web (love.js)
├── .github/workflows/
│   └── build.yml             # CI/CD: .love, web deploy, macOS .app
└── love2d-app/               # App iOS nativo (SwiftUI)
    └── love2d-app/
        ├── love2d_appApp.swift   # Entry point do app
        ├── ContentView.swift     # Tela principal + painel de personagens
        └── GameView.swift        # Motor do jogo + renderizacao Canvas
```

---

## 3. Implementacao Love2D (Desktop + Web)

### 3.1 Arquivo: `conf.lua`

Configura a janela Love2D para o tamanho widget:

- **Resolucao:** 340 x 250 pixels
- **Love2D version:** 11.5
- **Modulos ativos:** joystick, touch

### 3.2 Arquivo: `main.lua`

Contem toda a logica do jogo em Lua puro, sem dependencias externas.

#### Estruturas de Dados

| Variavel | Tipo | Descricao |
|---|---|---|
| `character` | table | Jogador controlavel (posicao, velocidade, estado de animacao) |
| `npcs` | table[] | Array de NPCs com IA autonoma |
| `cat` | table | Gato com IA e animacao de cauda |
| `world` | table | Configuracao do mundo (gravidade, chao) |
| `birthdayTable` | table | Posicao e dimensoes da mesa de aniversario |
| `input` | table | Estado das teclas (left, right, jump) |
| `touchControls` | table | Botoes touch e mapeamento de toques ativos |

#### Definicoes de NPCs (`npcDefs`)

7 personagens pre-definidos com paletas de cores unicas:

- 3 meninos: vermelho, verde, ciano
- 3 meninas: rosa, dourado, roxo (com cores de cabelo distintas)
- 1 aniversariante: laranja, com `birthday = true`

Cada NPC possui:
- **Paleta:** `body`, `skin`, `legs` (e `hair` para meninas)
- **Genero:** `"boy"` ou `"girl"` (afeta renderizacao de cabelo, vestido, cilios)
- **Flag birthday:** ativa chapeu de festa e lingua de sogra

#### Game Loop (`love.update`)

Executado a cada frame (~60fps):

1. **Input do jogador:** resolve `moveX` a partir de `input.left/right`, aplica velocidade
2. **Pulo:** consome `input.jump`, aplica `jumpForce = -220`, desativa `onGround`
3. **Gravidade:** `vy += 500 * dt` quando no ar
4. **Colisao com chao:** trava `y` em `groundY`, reseta `vy`, reativa `onGround`
5. **Limites de tela:** `clamp(x, 0, sw - w)`
6. **Estado de animacao:** `"idle"`, `"walk"`, `"jump"` baseado em movimento
7. **Timer de animacao:** cicla `animFrame` 1-4 a cada 0.15s

**IA dos NPCs** (por NPC):
- `aiTimer` decrementa por `dt`
- Quando expira: 40% chance de ficar idle, 60% chance de andar (direcao aleatoria)
- Novo timer: `random(1, 4)` segundos
- Inverte direcao nas bordas da tela

**IA do Gato:**
- Mesma logica dos NPCs, mas 50/50 idle/walk
- Timer mais curto: `random(1, 3)` segundos
- `tailTimer` incrementa continuamente para animacao da cauda

#### Renderizacao (`love.draw`)

Camadas desenhadas em ordem (de tras para frente):

1. **Ceu:** retangulo azul `(0.4, 0.7, 1)` preenchendo tela
2. **Chao:** retangulo verde + linha de separacao
3. **Mesa de aniversario** (`drawBirthdayTable`)
4. **Gato** (`drawCat`)
5. **NPCs** (loop)
6. **Jogador** (por cima de tudo)
7. **Controles touch** (condicional)
8. **HUD** (texto)

#### Renderizacao Procedural de Personagens (`drawPerson`)

Cada personagem e desenhado pixel a pixel usando `love.graphics.rectangle`, `polygon` e `circle`. Nao usa sprites/texturas.

**Transformacoes:**
```
translate(cx + w/2, cy)  -- centro do personagem
scale(facing, 1)          -- espelha horizontalmente (-1 = esquerda)
translate(-w/2, 0)        -- volta ao canto
```

**Partes do corpo (coordenadas relativas ao topo-esquerdo):**

| Parte | Boy | Girl | Birthday |
|---|---|---|---|
| Chapeu | - | - | Cone dourado + faixa vermelha + pompom rosa |
| Cabelo | - | Retangulo longo + franja | - |
| Cabeca | 3,0 8x8 | 3,0 8x8 | Igual + sorriso |
| Olhos | 6,2 e 9,2 (piscam frame 4) | + cilios | Igual |
| Corpo | 3,8 8x10 | Vestido trapezoidal | Igual |
| Pernas | 3,18 e 8,18 | 4,16 e 8,16 (mais finas) | Igual |
| Bracos | 0,9 e 11,9 (balancam) | Igual | Braco frontal levantado |
| Lingua de sogra | - | - | Tubo animado com ponta vermelha |

**Animacoes procedurais:**
- **Pernas:** `sin(time * 10) * 2` offset vertical alternado
- **Bracos:** `sin(time * 10) * 3` offset vertical alternado
- **Olhos:** `animFrame == 4` → altura 1px (piscada)
- **Lingua de sogra:** `sin(time * 4) * 0.5 + 0.5` controla comprimento (7-17px)
- **Ponta da lingua:** `sin(time * 6) * 1.5` oscilacao vertical

#### Renderizacao do Gato (`drawCat`)

Componentes: corpo (8x5), cabeca (5x5), 2 orelhas triangulares com interior rosa, olhos verdes, nariz rosa, 3 pernas animadas, cauda com curva sinusoidal.

- **Cauda:** `line(1,-4, -2,-7+wave, -1,-10+wave*0.5)` onde `wave = sin(tailTimer * 3) * 2.5`
- **Pernas:** `sin(time * 12) * 1` quando andando

#### Mesa de Aniversario (`drawBirthdayTable`)

- 2 pernas de madeira + tampo marrom + listras vermelhas de toalha
- Bolo de 2 andares com glacê rosa e branco
- 5 velas coloridas com chamas animadas: `sin(time * 8 + i * 2) * 0.8`
- Banner "Feliz Aniversario!" centralizado acima

#### Input

| Metodo | Plataforma | Mapeamento |
|---|---|---|
| `love.keypressed/released` | Desktop | WASD, setas, Space, Escape |
| `love.touchpressed/released/moved` | iOS | Botoes on-screen (left, right, jump) |
| `love.mousepressed/released` | Web | Fallback para touch buttons |

Controles touch usam `pointInRect` para hit-testing e `touchControls.active[id]` para rastrear multiplos toques simultaneos.

---

## 4. Implementacao iOS Nativa (SwiftUI)

### 4.1 Decisao Arquitetural

Love2D nao roda nativamente dentro de SwiftUI. A cena foi **portada** para Swift puro usando `TimelineView` + `Canvas` do SwiftUI, que fornece:

- Renderizacao 2D via `GraphicsContext` (equivalente a `love.graphics`)
- Loop de animacao a ~60fps via `TimelineView(.animation)`
- Gestos touch nativos via `DragGesture`

### 4.2 Arquivo: `love2d_appApp.swift`

Entry point minimo — apenas instancia `ContentView` como root scene.

### 4.3 Arquivo: `ContentView.swift`

Layout principal da tela:

```
ZStack (fundo preto) {
    VStack {
        GameView (340x250, rounded corners)
        VStack "Convidados" {
            Header + botao "Adicionar"
            ScrollView {
                CharacterRow (Gato)
                ForEach (NPCs) { CharacterRow }
            }
        }
    }
}
```

**CharacterRow:** componente reutilizavel com:
- Icone SF Symbol colorido (`cat.fill`, `figure.stand`, `figure.dress.line.vertical.figure`)
- Nome do personagem
- Botao toggle de aniversario (party.popper.fill) → amarelo quando ativo
- Botao de remocao (xmark.circle.fill) → vermelho, ausente para o gato

### 4.4 Arquivo: `GameView.swift`

#### Modelo de Dados

**`Person` (Identifiable):**
```swift
id: UUID, name: String
x, y, w(14), h(22): Double          // posicao e dimensoes
vx, speed, facing: Double            // movimento
animTimer, animFrame, state: ...     // animacao
aiTimer, aiAction: ...               // IA
palette: Palette (body, skin, legs)  // cores
gender: Gender (.boy, .girl)
hairColor: Color?                    // opcional, so meninas
birthday: Bool                       // chapeu + lingua de sogra
```

**`Cat` (Identifiable):**
```swift
id: UUID, name: String("Gato")
x, y, w(10): Double
facing, speed(25), vx: Double
state, aiTimer, aiAction: ...
tailTimer: Double
birthday: Bool                       // suporta chapeu no gato
```

**`PersonPreset`:** pool de 10 presets (5 meninos, 5 meninas) com nomes brasileiros para adicao dinamica de personagens.

#### GameState (`@Observable`)

Classe observavel que mantem todo o estado do jogo. SwiftUI re-renderiza automaticamente quando propriedades mudam.

**Propriedades principais:**
- `sw/sh`: 340x250 (constantes)
- `groundY`: 216 (sh - 34)
- `player`: Person controlavel
- `npcs`: [Person] — array mutavel
- `cat`: Cat
- `time`: tempo acumulado para animacoes

**Game loop:**
```swift
TimelineView(.animation) → onChange(of: timeline.date) → game.tick(now:)
    → calcula dt desde lastTick
    → chama update(dt:)
```

Isso resolve o problema de `@State` nao ser mutavel dentro do closure do `Canvas`.

**API publica:**
- `addRandomNPC()` — cicla pelo pool de presets
- `removeNPC(at:)` — remove por indice
- `toggleBirthday(npcIndex:)` — alterna flag de aniversario em NPC
- `toggleCatBirthday()` — alterna flag de aniversario no gato

#### Renderizacao Canvas

Usa `GraphicsContext` do SwiftUI, equivalente ao `love.graphics`:

| Love2D | SwiftUI Canvas |
|---|---|
| `love.graphics.rectangle("fill", x, y, w, h)` | `ctx.fill(Path(CGRect(...)), with: .color(...))` |
| `love.graphics.circle("fill", x, y, r)` | `ctx.fill(Path(ellipseIn: CGRect(...)), with: ...)` |
| `love.graphics.polygon("fill", ...)` | `ctx.fill(Path { p in p.move(...); p.addLine(...) }, ...)` |
| `love.graphics.line(...)` | `ctx.stroke(Path { ... }, with: ..., lineWidth: ...)` |
| `love.graphics.push/pop()` | `var c = ctx` (copia, GraphicsContext e value type) |
| `love.graphics.translate(x, y)` | `c.translateBy(x:y:)` |
| `love.graphics.scale(sx, sy)` | `c.scaleBy(x:y:)` |
| `love.graphics.print(text, x, y)` | `ctx.draw(Text(...), at: CGPoint(...))` |

**Chapeu de aniversario no gato:**
Renderizado acima das orelhas com coordenadas ajustadas (`y: -12` a `-22`), inclui lingua de sogra saindo da boca do gato.

#### Touch Handling

Divisao da area de toque em zonas:

```
+----------------------------------+
|         JUMP (qualquer toque)    |  y < 170
|                                  |
+----------+----------+------------+
|  LEFT    |  RIGHT   |    JUMP    |  y > 170
|  x < 80  | x < 160  |  x > 260  |
+----------+----------+------------+
```

---

## 5. CI/CD (GitHub Actions)

### Arquivo: `.github/workflows/build.yml`

Pipeline acionado em push/PR para `main`:

```
build-love ──┬── build-web ──── deploy-web (GitHub Pages)
             └── build-macos
```

#### Job 1: `build-love`
- Empacota `main.lua` + `conf.lua` em `character2d.love` (ZIP)
- Upload como artifact

#### Job 2: `build-web`
- Depende de `build-love`
- Usa `npx love.js@0.9.0` para compilar `.love` → WebAssembly
- Copia `web/index.html` customizado
- Upload como pages artifact

#### Job 3: `deploy-web`
- Apenas em push para `main`
- Deploya para GitHub Pages
- URL: `edilson.dev/character-2d/`

#### Job 4: `build-macos`
- Depende de `build-love`
- Baixa Love2D 11.5 para macOS
- Cria bundle `.app` com:
  - Copia `love.app` → `Character 2D.app`
  - Injeta `character2d.love` em `Contents/Resources/`
  - Atualiza `Info.plist` (nome e bundle ID)
- Upload como artifact ZIP

---

## 6. Build e Execucao

### 6.1 Desktop (macOS)

```bash
# Instalar Love2D
brew install love

# Rodar direto
love .
# ou
make run

# Empacotar .love
make love
```

### 6.2 Web

```bash
make web
npx serve build/web
```

### 6.3 iOS (Simulator)

```bash
cd love2d-app

# Build
xcodebuild -project love2d-app.xcodeproj \
  -scheme love2d-app \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -configuration Debug build

# Instalar e rodar
xcrun simctl install booted <path-to-app>
xcrun simctl launch booted com.edilson.love2d-app
```

### 6.4 iOS (Device)

Abrir `love2d-app.xcodeproj` no Xcode, selecionar device fisico, Build & Run.
- **Development Team:** `5T3LZC3A68`
- **Bundle ID:** `com.edilson.love2d-app`
- **Deployment Target:** iOS 26.2

---

## 7. Especificacoes Tecnicas

| Parametro | Valor |
|---|---|
| Canvas | 340 x 250 px |
| Tamanho do personagem | 14 x 22 px |
| Tamanho do gato | 10 x 8 px |
| Mesa de aniversario | 44 x 17 px |
| Bolo | 20 x 19 px (2 andares) |
| Gravidade | 500 px/s^2 |
| Velocidade do jogador | 90 px/s |
| Forca de pulo | -220 px/s |
| Velocidade dos NPCs | 15-50 px/s (aleatorio) |
| Velocidade do gato | 25 px/s |
| Frame rate animacao | 0.15s/frame (person), 0.2s/frame (cat) |
| Altura do chao | 34 px do fundo |
| Pool de presets | 10 personagens (5M, 5F) |

---

## 8. Dependencias

### Love2D (Desktop/Web)
- **Love2D 11.5** — framework de jogos 2D em Lua
- **love.js 0.9.0** — compilador Love2D → WebAssembly (via Emscripten)
- **Node.js 20** — para `npx love.js` e `npx serve`

### iOS
- **Xcode 26.2** — IDE e toolchain Swift
- **SwiftUI** — framework de UI declarativa (nativo, sem pods)
- **Swift 5.0** — linguagem
- **iOS 26.2 SDK** — target de deployment

### CI
- **GitHub Actions** — automacao
- `actions/checkout@v4`, `setup-node@v4`, `upload-artifact@v4`
- `deploy-pages@v4`, `upload-pages-artifact@v3`

---

## 9. Licenca

MIT
