//
//  GameView.swift
//  love2d-app
//
//  Top-down RPG birthday party scene — native Swift port of the Love2D game
//  340×250 widget-sized canvas with animated characters, cats, and dogs
//

import SwiftUI

// MARK: - Data types

struct Palette {
    var body: Color
    var skin: Color
    var legs: Color
}

enum Gender: String, CaseIterable { case boy, girl }

struct Person: Identifiable {
    let id: UUID
    var name: String
    var x: Double
    var y: Double
    let w: Double = 14
    let h: Double = 22
    var speed: Double
    var facing: Double
    var dir: String = "down"
    var animTimer: Double
    var animFrame: Int
    var state: String = "idle"
    var aiTimer: Double
    var aiAction: String = "idle"
    var aiDirX: Double = 0
    var aiDirY: Double = 0
    var palette: Palette
    var gender: Gender
    var hairColor: Color?
    var birthday: Bool = false
    var blowerTimer: Double = 0
}

struct CatPet: Identifiable {
    let id = UUID()
    var name: String
    var x: Double
    var y: Double
    let w: Double = 10
    var facing: Double = 1
    var speed: Double = 20
    var state: String = "idle"
    var animTimer: Double = 0
    var animFrame: Int = 1
    var aiTimer: Double = 2
    var aiAction: String = "idle"
    var aiDirX: Double = 0
    var aiDirY: Double = 0
    var tailTimer: Double = 0
    var birthday: Bool = false
    // Colors
    var color: Color
    var earInner: Color
    var legColor: Color
    var eyeColor: Color
}

struct DogPet: Identifiable {
    let id = UUID()
    var name: String
    var x: Double
    var y: Double
    let w: Double = 12
    let h: Double = 9
    var facing: Double = 1
    var speed: Double = 28
    var state: String = "idle"
    var animTimer: Double = 0
    var animFrame: Int = 1
    var aiTimer: Double = 2
    var aiAction: String = "idle"
    var aiDirX: Double = 0
    var aiDirY: Double = 0
    var tailTimer: Double = 0
    // Colors
    var color: (Double, Double, Double)
    var earColor: Color
    var legColor: Color
    var nose: Color
    var eyeColor: Color
}

/// Unified type for the character list
enum CharacterEntry: Identifiable {
    case person(Int)
    case cat(Int)
    case dog(Int)

    var id: String {
        switch self {
        case .person(let i): return "p\(i)"
        case .cat(let i): return "cat\(i)"
        case .dog(let i): return "dog\(i)"
        }
    }
}

// MARK: - Preset palettes for random add

struct PersonPreset {
    let body: Color; let skin: Color; let legs: Color
    let gender: Gender; let hair: Color?; let name: String
}

let presets: [PersonPreset] = [
    .init(body: Color(r:0.9,g:0.2,b:0.2), skin: Color(r:0.85,g:0.7,b:0.55), legs: Color(r:0.4,g:0.2,b:0.2), gender: .boy, hair: nil, name: "Carlos"),
    .init(body: Color(r:0.2,g:0.8,b:0.3), skin: Color(r:1,g:0.9,b:0.75), legs: Color(r:0.2,g:0.4,b:0.2), gender: .boy, hair: nil, name: "Joao"),
    .init(body: Color(r:0.1,g:0.7,b:0.7), skin: Color(r:0.55,g:0.4,b:0.3), legs: Color(r:0.1,g:0.4,b:0.4), gender: .boy, hair: nil, name: "Pedro"),
    .init(body: Color(r:0.8,g:0.3,b:0.1), skin: Color(r:0.9,g:0.75,b:0.6), legs: Color(r:0.5,g:0.2,b:0.05), gender: .boy, hair: nil, name: "Lucas"),
    .init(body: Color(r:0.3,g:0.3,b:0.7), skin: Color(r:1,g:0.85,b:0.7), legs: Color(r:0.2,g:0.2,b:0.5), gender: .boy, hair: nil, name: "Rafael"),
    .init(body: Color(r:0.9,g:0.4,b:0.7), skin: Color(r:1,g:0.85,b:0.7), legs: Color(r:0.6,g:0.2,b:0.4), gender: .girl, hair: Color(r:0.4,g:0.2,b:0.1), name: "Ana"),
    .init(body: Color(r:0.8,g:0.6,b:0.1), skin: Color(r:0.7,g:0.5,b:0.35), legs: Color(r:0.5,g:0.3,b:0.1), gender: .girl, hair: Color(r:0.15,g:0.1,b:0.05), name: "Maria"),
    .init(body: Color(r:0.6,g:0.2,b:0.8), skin: Color(r:0.95,g:0.8,b:0.65), legs: Color(r:0.3,g:0.1,b:0.4), gender: .girl, hair: Color(r:0.9,g:0.75,b:0.3), name: "Julia"),
    .init(body: Color(r:0.2,g:0.6,b:0.5), skin: Color(r:1,g:0.9,b:0.75), legs: Color(r:0.1,g:0.4,b:0.3), gender: .girl, hair: Color(r:0.6,g:0.3,b:0.15), name: "Bia"),
    .init(body: Color(r:0.95,g:0.5,b:0.3), skin: Color(r:0.85,g:0.7,b:0.55), legs: Color(r:0.6,g:0.3,b:0.15), gender: .girl, hair: Color(r:0.1,g:0.05,b:0.02), name: "Clara"),
]

// MARK: - Table collision rect

struct TableRect {
    let x: Double
    let y: Double
    let w: Double = 44
    let h: Double = 24
    var colX: Double { x - 2 }
    var colY: Double { y - 18 }
    var colW: Double { w + 4 }
    var colH: Double { h + 14 }
}

// MARK: - Game State

@Observable
class GameState {
    let sw: Double = 340
    let sh: Double = 250
    let minY: Double = 10
    var maxY: Double { sh - 8 }

    let table: TableRect

    // Player
    var player: Person
    var moveLeft = false
    var moveRight = false
    var moveUp = false
    var moveDown = false

    var npcs: [Person] = []
    var cats: [CatPet] = []
    var dogs: [DogPet] = []

    var time: Double = 0
    var lastTick: Date?
    private var addCounter = 0

    // Grass tilemap
    var tiles: [[Int]] = []
    let tileSize: Double = 10
    var tilesX: Int = 0
    var tilesY: Int = 0

    func tick(now: Date) {
        if let last = lastTick {
            let dt = min(now.timeIntervalSince(last), 0.05)
            update(dt: dt)
        }
        lastTick = now
    }

    init() {
        table = TableRect(x: 340 / 2 - 22, y: 250 / 2 - 5)

        player = Person(
            id: UUID(), name: "Voce",
            x: 40, y: 250 / 2 + 40, speed: 70, facing: 1,
            animTimer: 0, animFrame: 1,
            aiTimer: 0,
            palette: Palette(body: Color(r: 0.2, g: 0.5, b: 0.9),
                             skin: Color(r: 1, g: 0.85, b: 0.7),
                             legs: Color(r: 0.3, g: 0.3, b: 0.6)),
            gender: .boy
        )

        // NPCs
        let defs: [(PersonPreset, Bool)] = [
            (presets[0], false), (presets[1], false), (presets[2], false),
            (presets[5], false), (presets[6], false), (presets[7], false),
            (.init(body: Color(r:1,g:0.5,b:0.0), skin: Color(r:1,g:0.9,b:0.75), legs: Color(r:0.6,g:0.3,b:0.0), gender: .boy, hair: nil, name: "Mateus"), true),
        ]
        for d in defs {
            let p = d.0
            let startX = d.1 ? 340.0 / 2 + 28 : Double.random(in: 10...(340 - 24))
            let startY = d.1 ? 250.0 / 2 : Double.random(in: 30...(250 - 18))
            npcs.append(Person(
                id: UUID(), name: p.name,
                x: startX, y: startY,
                speed: Double.random(in: 12...35),
                facing: Bool.random() ? 1 : -1,
                animTimer: Double.random(in: 0...0.5),
                animFrame: Int.random(in: 1...4),
                aiTimer: Double.random(in: 0...3),
                palette: Palette(body: p.body, skin: p.skin, legs: p.legs),
                gender: p.gender, hairColor: p.hair,
                birthday: d.1
            ))
        }

        // Cats: orange + black
        cats = [
            CatPet(name: "Gato Laranja", x: 340 / 2 - 35, y: 250 / 2 + 15,
                   aiTimer: Double.random(in: 1...3), tailTimer: Double.random(in: 0...3),
                   color: Color(r: 0.95, g: 0.6, b: 0.2),
                   earInner: Color(r: 1, g: 0.75, b: 0.8),
                   legColor: Color(r: 0.9, g: 0.55, b: 0.15),
                   eyeColor: Color(r: 0.1, g: 0.6, b: 0.1)),
            CatPet(name: "Gato Preto", x: 340 / 2 + 50, y: 250 / 2 - 20,
                   facing: -1,
                   aiTimer: Double.random(in: 1...3), tailTimer: Double.random(in: 0...3),
                   color: Color(r: 0.15, g: 0.15, b: 0.15),
                   earInner: Color(r: 0.35, g: 0.25, b: 0.3),
                   legColor: Color(r: 0.1, g: 0.1, b: 0.1),
                   eyeColor: Color(r: 0.9, g: 0.7, b: 0.1)),
        ]

        // Dogs: white + black
        dogs = [
            DogPet(name: "Cachorro Branco", x: 80, y: 250 / 2 + 30,
                   aiTimer: Double.random(in: 1...3), tailTimer: Double.random(in: 0...3),
                   color: (0.95, 0.93, 0.9),
                   earColor: Color(r: 0.85, g: 0.8, b: 0.75),
                   legColor: Color(r: 0.88, g: 0.85, b: 0.82),
                   nose: Color(r: 0.2, g: 0.15, b: 0.15),
                   eyeColor: Color(r: 0.15, g: 0.1, b: 0.05)),
            DogPet(name: "Cachorro Preto", x: 340 - 60, y: 250 / 2 - 10,
                   facing: -1,
                   aiTimer: Double.random(in: 1...3), tailTimer: Double.random(in: 0...3),
                   color: (0.12, 0.12, 0.12),
                   earColor: Color(r: 0.08, g: 0.06, b: 0.06),
                   legColor: Color(r: 0.08, g: 0.08, b: 0.08),
                   nose: Color(r: 0.05, g: 0.03, b: 0.03),
                   eyeColor: Color(r: 0.5, g: 0.35, b: 0.15)),
        ]

        // Generate tilemap
        tilesX = Int(ceil(340 / tileSize))
        tilesY = Int(ceil(250 / tileSize))
        for _ in 0..<tilesY {
            var row: [Int] = []
            for _ in 0..<tilesX { row.append(Int.random(in: 1...5)) }
            tiles.append(row)
        }
    }

    // MARK: - Public API

    func addRandomNPC() {
        let p = presets[addCounter % presets.count]
        addCounter += 1
        npcs.append(Person(
            id: UUID(), name: p.name,
            x: Double.random(in: 20...(sw - 30)),
            y: Double.random(in: minY + 10...maxY - 10),
            speed: Double.random(in: 12...35),
            facing: Bool.random() ? 1 : -1,
            animTimer: 0, animFrame: 1,
            aiTimer: Double.random(in: 0...3),
            palette: Palette(body: p.body, skin: p.skin, legs: p.legs),
            gender: p.gender, hairColor: p.hair
        ))
    }

    func removeNPC(at index: Int) {
        guard npcs.indices.contains(index) else { return }
        npcs.remove(at: index)
    }

    func toggleBirthday(npcIndex: Int) {
        guard npcs.indices.contains(npcIndex) else { return }
        npcs[npcIndex].birthday.toggle()
    }

    func toggleCatBirthday(index: Int) {
        guard cats.indices.contains(index) else { return }
        cats[index].birthday.toggle()
    }

    // MARK: - Collision

    private func resolveTableCollision(ex: Double, ey: Double, ew: Double) -> (Double, Double) {
        let footH = 6.0
        let fx = ex, fy = ey - footH
        let fw = ew, fh = footH

        let t = table
        guard fx < t.colX + t.colW && fx + fw > t.colX &&
              fy < t.colY + t.colH && fy + fh > t.colY else {
            return (ex, ey)
        }

        let oL = (fx + fw) - t.colX
        let oR = (t.colX + t.colW) - fx
        let oT = (fy + fh) - t.colY
        let oB = (t.colY + t.colH) - fy
        let m = min(oL, oR, oT, oB)

        var nx = ex, ny = ey
        if m == oL { nx = t.colX - ew }
        else if m == oR { nx = t.colX + t.colW }
        else if m == oT { ny = t.colY }
        else { ny = t.colY + t.colH + footH }
        return (nx, ny)
    }

    private func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        min(max(v, lo), hi)
    }

    // MARK: - Update

    func update(dt: Double) {
        time += dt

        // Player (8-dir)
        var mx: Double = 0, my: Double = 0
        if moveLeft { mx -= 1 }
        if moveRight { mx += 1 }
        if moveUp { my -= 1 }
        if moveDown { my += 1 }

        if mx != 0 && my != 0 {
            let inv = 1.0 / sqrt(2.0)
            mx *= inv; my *= inv
        }

        player.x += mx * player.speed * dt
        player.y += my * player.speed * dt
        player.x = clamp(player.x, 0, sw - player.w)
        player.y = clamp(player.y, minY, maxY)

        let resolved = resolveTableCollision(ex: player.x, ey: player.y, ew: player.w)
        player.x = resolved.0; player.y = resolved.1

        if mx != 0 { player.facing = mx > 0 ? 1 : -1 }
        if mx != 0 || my != 0 {
            player.state = "walk"
            if abs(mx) >= abs(my) { player.dir = mx > 0 ? "right" : "left" }
            else { player.dir = my > 0 ? "down" : "up" }
        } else {
            player.state = "idle"
        }

        player.animTimer += dt
        if player.animTimer >= 0.15 { player.animTimer -= 0.15; player.animFrame = player.animFrame % 4 + 1 }

        // NPCs (2D wander)
        for i in npcs.indices {
            npcs[i].aiTimer -= dt
            if npcs[i].aiTimer <= 0 {
                if Double.random(in: 0...1) < 0.35 {
                    npcs[i].aiAction = "idle"
                    npcs[i].aiDirX = 0; npcs[i].aiDirY = 0
                } else {
                    npcs[i].aiAction = "walk"
                    let angle = Double.random(in: 0...(Double.pi * 2))
                    npcs[i].aiDirX = cos(angle)
                    npcs[i].aiDirY = sin(angle)
                }
                npcs[i].aiTimer = Double.random(in: 1...4)
            }

            if npcs[i].aiAction == "walk" {
                npcs[i].x += npcs[i].aiDirX * npcs[i].speed * dt
                npcs[i].y += npcs[i].aiDirY * npcs[i].speed * dt
                npcs[i].state = "walk"
                if npcs[i].aiDirX != 0 { npcs[i].facing = npcs[i].aiDirX > 0 ? 1 : -1 }
            } else {
                npcs[i].state = "idle"
            }

            if npcs[i].x < 0 { npcs[i].x = 0; npcs[i].aiDirX = abs(npcs[i].aiDirX) }
            if npcs[i].x + npcs[i].w > sw { npcs[i].x = sw - npcs[i].w; npcs[i].aiDirX = -abs(npcs[i].aiDirX) }
            if npcs[i].y < minY { npcs[i].y = minY; npcs[i].aiDirY = abs(npcs[i].aiDirY) }
            if npcs[i].y > maxY { npcs[i].y = maxY; npcs[i].aiDirY = -abs(npcs[i].aiDirY) }

            let nr = resolveTableCollision(ex: npcs[i].x, ey: npcs[i].y, ew: npcs[i].w)
            npcs[i].x = nr.0; npcs[i].y = nr.1

            npcs[i].animTimer += dt
            if npcs[i].animTimer >= 0.15 { npcs[i].animTimer -= 0.15; npcs[i].animFrame = npcs[i].animFrame % 4 + 1 }
            if npcs[i].birthday { npcs[i].blowerTimer += dt }
        }

        // Cats
        for i in cats.indices {
            cats[i].aiTimer -= dt
            if cats[i].aiTimer <= 0 {
                if Double.random(in: 0...1) < 0.45 {
                    cats[i].aiAction = "idle"; cats[i].aiDirX = 0; cats[i].aiDirY = 0
                } else {
                    cats[i].aiAction = "walk"
                    let angle = Double.random(in: 0...(Double.pi * 2))
                    cats[i].aiDirX = cos(angle); cats[i].aiDirY = sin(angle)
                }
                cats[i].aiTimer = Double.random(in: 1...3)
            }
            if cats[i].aiAction == "walk" {
                cats[i].x += cats[i].aiDirX * cats[i].speed * dt
                cats[i].y += cats[i].aiDirY * cats[i].speed * dt
                cats[i].state = "walk"
                if cats[i].aiDirX != 0 { cats[i].facing = cats[i].aiDirX > 0 ? 1 : -1 }
            } else { cats[i].state = "idle" }

            if cats[i].x < 0 { cats[i].x = 0; cats[i].aiDirX = abs(cats[i].aiDirX) }
            if cats[i].x + cats[i].w > sw { cats[i].x = sw - cats[i].w; cats[i].aiDirX = -abs(cats[i].aiDirX) }
            if cats[i].y < minY { cats[i].y = minY; cats[i].aiDirY = abs(cats[i].aiDirY) }
            if cats[i].y > maxY { cats[i].y = maxY; cats[i].aiDirY = -abs(cats[i].aiDirY) }

            let cr = resolveTableCollision(ex: cats[i].x, ey: cats[i].y, ew: cats[i].w)
            cats[i].x = cr.0; cats[i].y = cr.1
            cats[i].tailTimer += dt
            cats[i].animTimer += dt
            if cats[i].animTimer >= 0.2 { cats[i].animTimer -= 0.2; cats[i].animFrame = cats[i].animFrame % 2 + 1 }
        }

        // Dogs
        for i in dogs.indices {
            dogs[i].aiTimer -= dt
            if dogs[i].aiTimer <= 0 {
                if Double.random(in: 0...1) < 0.4 {
                    dogs[i].aiAction = "idle"; dogs[i].aiDirX = 0; dogs[i].aiDirY = 0
                } else {
                    dogs[i].aiAction = "walk"
                    let angle = Double.random(in: 0...(Double.pi * 2))
                    dogs[i].aiDirX = cos(angle); dogs[i].aiDirY = sin(angle)
                }
                dogs[i].aiTimer = Double.random(in: 1...3.5)
            }
            if dogs[i].aiAction == "walk" {
                dogs[i].x += dogs[i].aiDirX * dogs[i].speed * dt
                dogs[i].y += dogs[i].aiDirY * dogs[i].speed * dt
                dogs[i].state = "walk"
                if dogs[i].aiDirX != 0 { dogs[i].facing = dogs[i].aiDirX > 0 ? 1 : -1 }
            } else { dogs[i].state = "idle" }

            if dogs[i].x < 0 { dogs[i].x = 0; dogs[i].aiDirX = abs(dogs[i].aiDirX) }
            if dogs[i].x + dogs[i].w > sw { dogs[i].x = sw - dogs[i].w; dogs[i].aiDirX = -abs(dogs[i].aiDirX) }
            if dogs[i].y < minY { dogs[i].y = minY; dogs[i].aiDirY = abs(dogs[i].aiDirY) }
            if dogs[i].y > maxY { dogs[i].y = maxY; dogs[i].aiDirY = -abs(dogs[i].aiDirY) }

            let dr = resolveTableCollision(ex: dogs[i].x, ey: dogs[i].y, ew: dogs[i].w)
            dogs[i].x = dr.0; dogs[i].y = dr.1
            dogs[i].tailTimer += dt
            dogs[i].animTimer += dt
            if dogs[i].animTimer >= 0.2 { dogs[i].animTimer -= 0.2; dogs[i].animFrame = dogs[i].animFrame % 2 + 1 }
        }
    }
}

// MARK: - Color helper

extension Color {
    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - GameView

struct GameView: View {
    var game: GameState

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = game.time

                // Grass tilemap
                drawGrass(ctx: ctx)

                // Y-sort all entities
                struct Entity {
                    let type: String
                    let index: Int
                    let y: Double
                }
                var entities: [Entity] = []
                entities.append(Entity(type: "table", index: 0, y: game.table.y))
                for i in game.cats.indices { entities.append(Entity(type: "cat", index: i, y: game.cats[i].y)) }
                for i in game.dogs.indices { entities.append(Entity(type: "dog", index: i, y: game.dogs[i].y)) }
                for i in game.npcs.indices { entities.append(Entity(type: "npc", index: i, y: game.npcs[i].y)) }
                entities.append(Entity(type: "player", index: 0, y: game.player.y))

                entities.sort { $0.y < $1.y }

                for e in entities {
                    switch e.type {
                    case "table": drawTable(ctx: ctx, t: t)
                    case "cat": drawCat(ctx: ctx, cat: game.cats[e.index], t: t)
                    case "dog": drawDog(ctx: ctx, dog: game.dogs[e.index], t: t)
                    case "npc": drawPerson(ctx: ctx, p: game.npcs[e.index], t: t)
                    case "player": drawPerson(ctx: ctx, p: game.player, t: t)
                    default: break
                    }
                }
            }
            .frame(width: 340, height: 250)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in handleTouch(value.location) }
                    .onEnded { _ in releaseTouch() }
            )
            .onChange(of: timeline.date) { _, newValue in
                game.tick(now: newValue)
            }
        }
    }

    // MARK: - Touch (invisible diagonal zones from center)
    // Screen split by diagonals: touch closest to left edge = left, etc.

    func handleTouch(_ pt: CGPoint) {
        game.moveLeft = false; game.moveRight = false
        game.moveUp = false; game.moveDown = false

        let cx = game.sw / 2, cy = game.sh / 2
        let dx = Double(pt.x) - cx
        let dy = Double(pt.y) - cy
        let aspect = game.sw / game.sh

        if abs(dx) > abs(dy * aspect) {
            if dx > 0 { game.moveRight = true }
            else { game.moveLeft = true }
        } else {
            if dy > 0 { game.moveDown = true }
            else { game.moveUp = true }
        }
    }

    func releaseTouch() {
        game.moveLeft = false; game.moveRight = false
        game.moveUp = false; game.moveDown = false
    }

    // MARK: - Draw grass tilemap

    func drawGrass(ctx: GraphicsContext) {
        let ts = game.tileSize
        let grassColors: [Color] = [
            Color(r: 0.28, g: 0.65, b: 0.28),
            Color(r: 0.32, g: 0.70, b: 0.30),
            Color(r: 0.26, g: 0.62, b: 0.26),
            Color(r: 0.30, g: 0.68, b: 0.32),
            Color(r: 0.34, g: 0.72, b: 0.28),
        ]

        for ty in 0..<game.tilesY {
            for tx in 0..<game.tilesX {
                let v = game.tiles[ty][tx]
                let px = Double(tx) * ts
                let py = Double(ty) * ts
                ctx.fill(Path(CGRect(x: px, y: py, width: ts, height: ts)),
                         with: .color(grassColors[v - 1]))
            }
        }

        // Subtle path
        ctx.fill(Path(CGRect(x: 0, y: game.sh / 2 - 15, width: game.sw, height: 30)),
                 with: .color(Color(r: 0.38, g: 0.60, b: 0.30, a: 0.3)))
    }

    // MARK: - Draw table

    func drawTable(ctx: GraphicsContext, t: Double) {
        let tx = game.table.x
        let ty = game.table.y

        // Shadow
        ctx.fill(Path(ellipseIn: CGRect(x: tx + 22 - 26, y: ty + 4 - 8, width: 52, height: 16)),
                 with: .color(Color(r: 0, g: 0, b: 0, a: 0.15)))

        // Table top
        ctx.fill(Path(roundedRect: CGRect(x: tx, y: ty - 17, width: 44, height: 20), cornerRadius: 3),
                 with: .color(Color(r: 0.6, g: 0.35, b: 0.15)))
        for i in 0..<5 {
            ctx.fill(Path(CGRect(x: tx + Double(i) * 9, y: ty - 17, width: 5, height: 20)),
                     with: .color(Color(r: 1, g: 0.3, b: 0.3, a: 0.45)))
        }
        // Edge
        ctx.fill(Path(roundedRect: CGRect(x: tx, y: ty + 1, width: 44, height: 3), cornerRadius: 2),
                 with: .color(Color(r: 0.5, g: 0.28, b: 0.1)))

        // Cake
        let cakeX = tx + 10, cakeY = ty - 10
        ctx.fill(Path(CGRect(x: cakeX, y: cakeY - 11, width: 20, height: 7)), with: .color(Color(r: 0.9, g: 0.75, b: 0.5)))
        ctx.fill(Path(CGRect(x: cakeX, y: cakeY - 12, width: 20, height: 2)), with: .color(Color(r: 1, g: 0.4, b: 0.6)))
        ctx.fill(Path(CGRect(x: cakeX + 3, y: cakeY - 18, width: 14, height: 7)), with: .color(Color(r: 0.95, g: 0.8, b: 0.55)))
        ctx.fill(Path(CGRect(x: cakeX + 3, y: cakeY - 19, width: 14, height: 2)), with: .color(.white))

        let candleColors: [Color] = [.red, .green, .blue, .yellow, .purple]
        for i in 0..<5 {
            let cx = cakeX + 5 + Double(i) * 2.5, cy = cakeY - 19
            ctx.fill(Path(CGRect(x: cx, y: cy - 5, width: 1.5, height: 5)), with: .color(candleColors[i]))
            let flicker = sin(t * 8 + Double(i) * 2) * 0.8
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 0.55, y: cy - 7.3 + flicker, width: 2.6, height: 2.6)),
                     with: .color(Color(r: 1, g: 0.9, b: 0.2)))
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 0.05, y: cy - 7.3 + flicker, width: 1.6, height: 1.6)),
                     with: .color(Color(r: 1, g: 0.6, b: 0.1)))
        }
    }

    // MARK: - Draw cat

    func drawCat(ctx: GraphicsContext, cat: CatPet, t: Double) {
        // Shadow
        ctx.fill(Path(ellipseIn: CGRect(x: cat.x + cat.w / 2 - 5, y: cat.y, width: 10, height: 4)),
                 with: .color(Color(r: 0, g: 0, b: 0, a: 0.15)))

        var c = ctx
        c.translateBy(x: cat.x + cat.w / 2, y: cat.y)
        c.scaleBy(x: cat.facing, y: 1)
        c.translateBy(x: -cat.w / 2, y: 0)

        let col = cat.color

        // Birthday hat
        if cat.birthday {
            c.fill(Path { p in p.move(to: .init(x: 6, y: -12)); p.addLine(to: .init(x: 12, y: -12)); p.addLine(to: .init(x: 9, y: -22)); p.closeSubpath() },
                   with: .color(Color(r: 1, g: 0.85, b: 0)))
            c.fill(Path { p in p.move(to: .init(x: 7, y: -14)); p.addLine(to: .init(x: 11, y: -14)); p.addLine(to: .init(x: 10, y: -18)); p.addLine(to: .init(x: 8, y: -18)); p.closeSubpath() },
                   with: .color(Color(r: 1, g: 0.2, b: 0.3)))
            c.fill(Path(ellipseIn: CGRect(x: 7.5, y: -23.5, width: 3, height: 3)),
                   with: .color(Color(r: 1, g: 0.3, b: 0.8)))
        }

        c.fill(Path(CGRect(x: 1, y: -5, width: 8, height: 5)), with: .color(col))
        c.fill(Path(CGRect(x: 7, y: -9, width: 5, height: 5)), with: .color(col))
        c.fill(Path { p in p.move(to: .init(x: 7.5, y: -9)); p.addLine(to: .init(x: 8.5, y: -12)); p.addLine(to: .init(x: 9.5, y: -9)); p.closeSubpath() }, with: .color(col))
        c.fill(Path { p in p.move(to: .init(x: 10.5, y: -9)); p.addLine(to: .init(x: 11.5, y: -12)); p.addLine(to: .init(x: 12.5, y: -9)); p.closeSubpath() }, with: .color(col))
        c.fill(Path { p in p.move(to: .init(x: 8, y: -9)); p.addLine(to: .init(x: 8.5, y: -11)); p.addLine(to: .init(x: 9, y: -9)); p.closeSubpath() }, with: .color(cat.earInner))
        c.fill(Path { p in p.move(to: .init(x: 11, y: -9)); p.addLine(to: .init(x: 11.5, y: -11)); p.addLine(to: .init(x: 12, y: -9)); p.closeSubpath() }, with: .color(cat.earInner))
        c.fill(Path(ellipseIn: CGRect(x: 8.2, y: -7.8, width: 1.6, height: 1.6)), with: .color(cat.eyeColor))
        c.fill(Path(ellipseIn: CGRect(x: 10.2, y: -7.8, width: 1.6, height: 1.6)), with: .color(cat.eyeColor))
        c.fill(Path(CGRect(x: 9.5, y: -5.5, width: 1, height: 0.8)), with: .color(Color(r: 1, g: 0.5, b: 0.5)))

        let legAnim = cat.state == "walk" ? sin(t * 12) * 1 : 0
        c.fill(Path(CGRect(x: 2, y: 0, width: 1.5, height: 2 - legAnim)), with: .color(cat.legColor))
        c.fill(Path(CGRect(x: 5, y: 0, width: 1.5, height: 2 + legAnim)), with: .color(cat.legColor))
        c.fill(Path(CGRect(x: 7, y: 0, width: 1.5, height: 2 + legAnim)), with: .color(cat.legColor))

        let tailWave = sin(cat.tailTimer * 3) * 2.5
        c.stroke(Path { p in p.move(to: .init(x: 1, y: -4)); p.addLine(to: .init(x: -2, y: -7 + tailWave)); p.addLine(to: .init(x: -1, y: -10 + tailWave * 0.5)) },
                 with: .color(col), lineWidth: 1)

        // Lingua de sogra for birthday cat
        if cat.birthday {
            c.fill(Path(CGRect(x: 12, y: -6, width: 3, height: 1.5)), with: .color(Color(r: 0.9, g: 0.1, b: 0.2)))
            let blowPhase = sin(t * 4) * 0.5 + 0.5
            let tubeLen = 5 + blowPhase * 8
            c.fill(Path(CGRect(x: 15, y: -5.8, width: tubeLen, height: 1.2)), with: .color(Color(r: 0.2, g: 0.8, b: 0.2)))
            var s: Double = 0
            while s < tubeLen - 1.5 {
                c.fill(Path(CGRect(x: 15 + s, y: -5.8, width: 1.2, height: 1.2)), with: .color(Color(r: 1, g: 0.85, b: 0)))
                s += 2.5
            }
            let tipX = 15 + tubeLen
            let tipWave = sin(t * 6) * 1.2
            c.fill(Path(ellipseIn: CGRect(x: tipX - 1, y: -6 + tipWave, width: 2.5, height: 2.5)), with: .color(Color(r: 0.9, g: 0.1, b: 0.2)))
        }
    }

    // MARK: - Draw dog

    func drawDog(ctx: GraphicsContext, dog: DogPet, t: Double) {
        let col = Color(r: dog.color.0, g: dog.color.1, b: dog.color.2)
        let snoutCol = Color(r: dog.color.0 * 0.95 + 0.05,
                             g: dog.color.1 * 0.95 + 0.05,
                             b: dog.color.2 * 0.95 + 0.05)

        // Shadow
        ctx.fill(Path(ellipseIn: CGRect(x: dog.x + dog.w / 2 - 6, y: dog.y, width: 12, height: 5)),
                 with: .color(Color(r: 0, g: 0, b: 0, a: 0.15)))

        var c = ctx
        c.translateBy(x: dog.x + dog.w / 2, y: dog.y)
        c.scaleBy(x: dog.facing, y: 1)
        c.translateBy(x: -dog.w / 2, y: 0)

        // Body
        c.fill(Path(CGRect(x: 1, y: -6, width: 9, height: 6)), with: .color(col))

        // Head
        c.fill(Path(CGRect(x: 8, y: -10, width: 6, height: 6)), with: .color(col))

        // Snout
        c.fill(Path(CGRect(x: 13, y: -8, width: 3, height: 3)), with: .color(snoutCol))

        // Nose
        c.fill(Path(CGRect(x: 15, y: -7.5, width: 1.5, height: 1.5)), with: .color(dog.nose))

        // Floppy ears
        c.fill(Path(roundedRect: CGRect(x: 8, y: -10, width: 2.5, height: 7), cornerRadius: 1),
               with: .color(dog.earColor))
        c.fill(Path(roundedRect: CGRect(x: 12, y: -10, width: 2.5, height: 7), cornerRadius: 1),
               with: .color(dog.earColor))

        // Eyes
        c.fill(Path(ellipseIn: CGRect(x: 9.1, y: -8.9, width: 1.8, height: 1.8)), with: .color(dog.eyeColor))
        c.fill(Path(ellipseIn: CGRect(x: 11.6, y: -8.9, width: 1.8, height: 1.8)), with: .color(dog.eyeColor))

        // Mouth line
        c.stroke(Path { p in p.move(to: .init(x: 14, y: -5.5)); p.addLine(to: .init(x: 15.5, y: -5)) },
                 with: .color(dog.nose), lineWidth: 0.5)

        // Legs
        let legAnim = dog.state == "walk" ? sin(t * 10) * 1.2 : 0
        c.fill(Path(CGRect(x: 2, y: 0, width: 2, height: 2.5 - legAnim)), with: .color(dog.legColor))
        c.fill(Path(CGRect(x: 5, y: 0, width: 2, height: 2.5 + legAnim)), with: .color(dog.legColor))
        c.fill(Path(CGRect(x: 7, y: 0, width: 2, height: 2.5 + legAnim)), with: .color(dog.legColor))
        c.fill(Path(CGRect(x: 9, y: 0, width: 2, height: 2.5 - legAnim)), with: .color(dog.legColor))

        // Tail (wagging)
        let tailWag = sin(dog.tailTimer * 5) * 2
        c.stroke(Path { p in p.move(to: .init(x: 1, y: -4)); p.addLine(to: .init(x: -1, y: -6 + tailWag)); p.addLine(to: .init(x: -2, y: -9 + tailWag * 0.5)) },
                 with: .color(col), lineWidth: 1.5)
    }

    // MARK: - Draw person

    func drawPerson(ctx: GraphicsContext, p: Person, t: Double) {
        // Shadow
        ctx.fill(Path(ellipseIn: CGRect(x: p.x + p.w / 2 - 6, y: p.y, width: 12, height: 5)),
                 with: .color(Color(r: 0, g: 0, b: 0, a: 0.15)))

        var c = ctx
        c.translateBy(x: p.x + p.w / 2, y: p.y - p.h)
        c.scaleBy(x: p.facing, y: 1)
        c.translateBy(x: -p.w / 2, y: 0)

        if p.birthday {
            c.fill(Path { pa in pa.move(to: .init(x: 4, y: 0)); pa.addLine(to: .init(x: 10, y: 0)); pa.addLine(to: .init(x: 7, y: -10)); pa.closeSubpath() },
                   with: .color(Color(r: 1, g: 0.85, b: 0)))
            c.fill(Path { pa in pa.move(to: .init(x: 5, y: -2)); pa.addLine(to: .init(x: 9, y: -2)); pa.addLine(to: .init(x: 8, y: -6)); pa.addLine(to: .init(x: 6, y: -6)); pa.closeSubpath() },
                   with: .color(Color(r: 1, g: 0.2, b: 0.3)))
            c.fill(Path(ellipseIn: CGRect(x: 5.5, y: -11.5, width: 3, height: 3)), with: .color(Color(r: 1, g: 0.3, b: 0.8)))
        }

        let hairColor = p.hairColor ?? Color(r: 0.3, g: 0.15, b: 0.05)
        if p.gender == .girl {
            c.fill(Path(CGRect(x: 2, y: -1, width: 10, height: 11)), with: .color(hairColor))
            c.fill(Path(CGRect(x: 3, y: -2, width: 8, height: 2)), with: .color(hairColor))
        }
        c.fill(Path(CGRect(x: 3, y: 0, width: 8, height: 8)), with: .color(p.palette.skin))
        if p.gender == .girl {
            c.fill(Path(CGRect(x: 3, y: -1, width: 8, height: 3)), with: .color(hairColor))
        }

        let eyeH: Double = (p.animFrame == 4 && p.state == "idle") ? 1 : 2
        c.fill(Path(CGRect(x: 6, y: 2, width: 1.5, height: eyeH)), with: .color(.black))
        c.fill(Path(CGRect(x: 9, y: 2, width: 1.5, height: eyeH)), with: .color(.black))
        if p.gender == .girl && eyeH > 1 {
            let lash = Path { pa in
                pa.move(to: .init(x: 6, y: 2)); pa.addLine(to: .init(x: 5.5, y: 1.5))
                pa.move(to: .init(x: 7.5, y: 2)); pa.addLine(to: .init(x: 8, y: 1.5))
                pa.move(to: .init(x: 9, y: 2)); pa.addLine(to: .init(x: 8.5, y: 1.5))
                pa.move(to: .init(x: 10.5, y: 2)); pa.addLine(to: .init(x: 11, y: 1.5))
            }
            c.stroke(lash, with: .color(.black), lineWidth: 0.5)
        }

        if p.birthday {
            c.stroke(Path { pa in pa.addArc(center: .init(x: 8, y: 5.5), radius: 2, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false) },
                     with: .color(Color(r: 0.8, g: 0.3, b: 0.3)), lineWidth: 0.5)
        } else {
            c.fill(Path(CGRect(x: 7, y: 5.5, width: 3, height: 1)), with: .color(Color(r: 0.8, g: 0.3, b: 0.3)))
        }

        if p.gender == .girl {
            c.fill(Path(CGRect(x: 3, y: 8, width: 8, height: 5)), with: .color(p.palette.body))
            c.fill(Path { pa in pa.move(to: .init(x: 1, y: 13)); pa.addLine(to: .init(x: 3, y: 8)); pa.addLine(to: .init(x: 11, y: 8)); pa.addLine(to: .init(x: 13, y: 13)); pa.closeSubpath() },
                   with: .color(p.palette.body))
            c.fill(Path(CGRect(x: 1, y: 13, width: 12, height: 3)), with: .color(p.palette.body))
        } else {
            c.fill(Path(CGRect(x: 3, y: 8, width: 8, height: 10)), with: .color(p.palette.body))
        }

        let legOff = p.state == "walk" ? sin(t * 10) * 2 : 0
        if p.gender == .girl {
            c.fill(Path(CGRect(x: 4, y: 16, width: 2, height: 6 - legOff)), with: .color(p.palette.legs))
            c.fill(Path(CGRect(x: 8, y: 16, width: 2, height: 6 + legOff)), with: .color(p.palette.legs))
        } else {
            c.fill(Path(CGRect(x: 3, y: 18, width: 3, height: 4 - legOff)), with: .color(p.palette.legs))
            c.fill(Path(CGRect(x: 8, y: 18, width: 3, height: 4 + legOff)), with: .color(p.palette.legs))
        }

        let armSwing = p.state == "walk" ? sin(t * 10) * 3 : 0
        if p.birthday {
            c.fill(Path(CGRect(x: 0, y: 9, width: 3, height: 6 - armSwing)), with: .color(p.palette.skin))
            c.fill(Path(CGRect(x: 11, y: 7, width: 3, height: 4)), with: .color(p.palette.skin))
            c.fill(Path(CGRect(x: 14, y: 7, width: 3, height: 2)), with: .color(Color(r: 0.9, g: 0.1, b: 0.2)))
            let blowPhase = sin(t * 4) * 0.5 + 0.5
            let tubeLen = 7 + blowPhase * 10
            c.fill(Path(CGRect(x: 17, y: 7.2, width: tubeLen, height: 1.5)), with: .color(Color(r: 0.2, g: 0.8, b: 0.2)))
            var s: Double = 0
            while s < tubeLen - 2 { c.fill(Path(CGRect(x: 17 + s, y: 7.2, width: 1.5, height: 1.5)), with: .color(Color(r: 1, g: 0.85, b: 0))); s += 3 }
            let tipX = 17 + tubeLen, tipWave = sin(t * 6) * 1.5
            c.fill(Path(ellipseIn: CGRect(x: tipX - 1.5, y: 7 + tipWave - 0.5, width: 3, height: 3)), with: .color(Color(r: 0.9, g: 0.1, b: 0.2)))
        } else {
            c.fill(Path(CGRect(x: 0, y: 9, width: 3, height: 6 + armSwing)), with: .color(p.palette.skin))
            c.fill(Path(CGRect(x: 11, y: 9, width: 3, height: 6 - armSwing)), with: .color(p.palette.skin))
        }
    }
}
