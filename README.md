# Character 2D

Cena animada estilo RPG top-down com tematica de festa de aniversario. Personagens, gatos, cachorros e uma mesa com bolo se movem livremente por um mapa de grama, com ordenacao por profundidade (Y-sorting) simulando perspectiva 2D classica.

## Plataformas

| Plataforma | Tecnologia | Diretorio |
|---|---|---|
| macOS Desktop | Love2D (Lua) | `/` (raiz) |
| Web (browser) | love.js (Emscripten) | `/web/` + CI build |
| iOS (nativo) | SwiftUI + Canvas | `/love2d-app/` |

## O que tem na cena

- **Jogador controlavel** — personagem azul, movimentacao 8-direcional com WASD ou touch
- **7 NPCs** — 3 meninos, 3 meninas e 1 aniversariante com chapeu de festa e lingua de sogra animada
- **2 Gatos** — um laranja e um preto, com orelhas pontudas, olhos coloridos e cauda ondulante
- **2 Cachorros** — um branco e um preto, com orelhas caidas, focinho, 4 patas animadas e rabo abanando
- **Mesa de aniversario** — mesa com toalha listrada, bolo de 2 andares, 5 velas com chamas animadas
- **Mapa de grama** — tilemap procedural com 5 variacoes de verde e uma trilha sutil no centro

## Como funciona

### Movimentacao
Todos os personagens e animais se movem livremente nos eixos X e Y. O jogador usa WASD (desktop) ou toque na tela (mobile/web). A IA dos NPCs e animais escolhe direcoes aleatorias em angulos 2D.

### Controles touch
A tela e dividida em 4 zonas invisiveis pelas diagonais a partir do centro. Tocar mais perto de uma borda move o personagem naquela direcao — como um D-pad gigante invisivel.

### Profundidade (Y-sorting)
Entidades com Y maior (mais abaixo na tela) sao desenhadas por cima, criando o efeito classico de profundidade de RPGs 2D.

### Colisao com a mesa
Todos os personagens e animais colidem com a mesa de aniversario e desviam dela automaticamente.

### Renderizacao procedural
Tudo e desenhado pixel a pixel usando primitivas geometricas (retangulos, circulos, poligonos). Nenhuma sprite ou textura externa e utilizada.

## Painel de personagens (iOS)

Abaixo do canvas do jogo, o app iOS exibe uma lista com todos os convidados:
- Adicionar novos NPCs de um pool de 10 presets com nomes brasileiros
- Remover NPCs individualmente
- Marcar qualquer personagem (incluindo gatos) como aniversariante — ativa chapeu e lingua de sogra

## Estrutura do projeto

```
character-2d/
├── main.lua              # Jogo Love2D completo (desktop + web)
├── conf.lua              # Configuracao Love2D (340x250)
├── Makefile              # make run, make love, make web
├── web/
│   └── index.html        # Shell HTML para build web
├── .github/workflows/
│   └── build.yml         # CI: .love, web deploy, macOS .app
└── love2d-app/           # App iOS nativo (SwiftUI)
    └── love2d-app/
        ├── love2d_appApp.swift   # Entry point
        ├── ContentView.swift     # Tela + painel de personagens
        └── GameView.swift        # Motor do jogo + Canvas
```

## Como rodar

### Desktop (macOS)
```bash
brew install love
love .
```

### Web
```bash
make web
npx serve build/web
```

### iOS (Simulator)
```bash
cd love2d-app
xcodebuild -project love2d-app.xcodeproj \
  -scheme love2d-app \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  build
```

### iOS (Device)
Abrir `love2d-app.xcodeproj` no Xcode e Build & Run no device.

## CI/CD

Push to `main` triggers:
- `.love` package build
- Web build deployed to **GitHub Pages**
- macOS `.app` bundle as a downloadable artifact

## Specs

| Parametro | Valor |
|---|---|
| Canvas | 340 x 250 px |
| Personagem | 14 x 22 px |
| Gato | 10 x 8 px |
| Cachorro | 12 x 9 px |
| Mesa | 44 x 24 px |
| Velocidade jogador | 70 px/s |
| Velocidade NPCs | 12-35 px/s |
| Velocidade gatos | 20 px/s |
| Velocidade cachorros | 28 px/s |
| Frame rate animacao | 0.15s (pessoas), 0.2s (animais) |

## Licenca

MIT
