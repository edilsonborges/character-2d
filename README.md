# Character 2D

A simple 2D animated character built with [LÖVE](https://love2d.org/) (Love2D), targeting **macOS**, **iOS**, and **Web**.

## Running locally (macOS)

```bash
brew install love
love .
```

Or use the Makefile:

```bash
make run
```

## Controls

| Input | Action |
|-------|--------|
| Arrow keys / WASD | Move left/right |
| Space / Up / W | Jump |
| On-screen buttons | Touch controls (mobile & web) |

## Building

### .love package

```bash
make love
```

### Web (love.js)

```bash
make web
npx serve build/web
```

### macOS .app

The CI workflow automatically builds a standalone `.app` bundle. Download it from the GitHub Actions artifacts.

### iOS

1. Clone the [love-ios](https://github.com/love2d/love-apple-dependencies) dependencies
2. Open the Love2D Xcode project for iOS
3. Replace the bundled game with `character2d.love`
4. Build and run on your device or simulator

See the [Love2D iOS wiki](https://love2d.org/wiki/Getting_Started#iOS) for details.

## CI/CD

Push to `main` triggers:

- `.love` package build
- Web build deployed to **GitHub Pages**
- macOS `.app` bundle as a downloadable artifact

## License

MIT
