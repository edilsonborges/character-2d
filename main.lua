-- Character 2D — top-down RPG birthday party (340x250)
-- Targets: macOS desktop, iOS widget, and web

local player = {}
local npcs = {}
local cats = {}
local dogs = {}
local world = {}
local input = {}
local touchControls = {}
local birthdayTable = {}

local isMobile = love.system.getOS() == "iOS" or love.system.getOS() == "Android"

-- NPC definitions
local npcDefs = {
    -- Boys
    { body = {0.9, 0.2, 0.2}, skin = {0.85, 0.7, 0.55}, legs = {0.4, 0.2, 0.2}, gender = "boy" },
    { body = {0.2, 0.8, 0.3}, skin = {1, 0.9, 0.75},    legs = {0.2, 0.4, 0.2}, gender = "boy" },
    { body = {0.1, 0.7, 0.7}, skin = {0.55, 0.4, 0.3},   legs = {0.1, 0.4, 0.4}, gender = "boy" },
    -- Girls
    { body = {0.9, 0.4, 0.7}, skin = {1, 0.85, 0.7},     legs = {0.6, 0.2, 0.4}, gender = "girl", hair = {0.4, 0.2, 0.1} },
    { body = {0.8, 0.6, 0.1}, skin = {0.7, 0.5, 0.35},   legs = {0.5, 0.3, 0.1}, gender = "girl", hair = {0.15, 0.1, 0.05} },
    { body = {0.6, 0.2, 0.8}, skin = {0.95, 0.8, 0.65},  legs = {0.3, 0.1, 0.4}, gender = "girl", hair = {0.9, 0.75, 0.3} },
    -- Birthday boy
    { body = {1, 0.5, 0.0}, skin = {1, 0.9, 0.75}, legs = {0.6, 0.3, 0.0}, gender = "boy", birthday = true },
}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())

    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

    -- World bounds for walkable area
    world.minY = 10   -- top boundary
    world.maxY = sh - 8
    world.minX = 0
    world.maxX = sw

    -- Birthday table in center of map
    birthdayTable.x = sw / 2 - 22
    birthdayTable.y = sh / 2 - 5
    birthdayTable.w = 44
    birthdayTable.h = 24
    -- Collision box (slightly smaller than visual for walkability)
    birthdayTable.colX = birthdayTable.x - 2
    birthdayTable.colY = birthdayTable.y - 18
    birthdayTable.colW = birthdayTable.w + 4
    birthdayTable.colH = birthdayTable.h + 14

    -- Player (top-down: x,y is the "foot" position)
    player.x = 40
    player.y = sh / 2 + 40
    player.w = 14
    player.h = 22
    player.speed = 70
    player.facing = 1        -- horizontal flip: 1=right, -1=left
    player.dir = "down"      -- facing direction for animation
    player.animTimer = 0
    player.animFrame = 1
    player.state = "idle"

    input.left = false
    input.right = false
    input.up = false
    input.down = false

    -- Spawn NPCs
    for _, def in ipairs(npcDefs) do
        local startX, startY
        if def.birthday then
            startX = sw / 2 + 28
            startY = sh / 2
        else
            startX = math.random(10, sw - 24)
            startY = math.random(world.minY + 20, world.maxY - 10)
        end
        table.insert(npcs, {
            x = startX, y = startY,
            w = 14, h = 22,
            speed = math.random(12, 35),
            facing = math.random() > 0.5 and 1 or -1,
            dir = "down",
            animTimer = math.random() * 0.5,
            animFrame = math.random(1, 4),
            state = "idle",
            aiTimer = math.random() * 3,
            aiAction = "idle",
            aiDirX = 0, aiDirY = 0,
            palette = { body = def.body, skin = def.skin, legs = def.legs },
            gender = def.gender,
            hair = def.hair,
            birthday = def.birthday or false,
            blowerTimer = 0,
        })
    end

    -- Cats (orange + black)
    local catDefs = {
        { color = {0.95, 0.6, 0.2}, earInner = {1, 0.75, 0.8}, legColor = {0.9, 0.55, 0.15}, eye = {0.1, 0.6, 0.1}, x = sw / 2 - 35, y = sh / 2 + 15 },
        { color = {0.15, 0.15, 0.15}, earInner = {0.35, 0.25, 0.3}, legColor = {0.1, 0.1, 0.1}, eye = {0.9, 0.7, 0.1}, x = sw / 2 + 50, y = sh / 2 - 20 },
    }
    for _, cd in ipairs(catDefs) do
        table.insert(cats, {
            x = cd.x, y = cd.y,
            w = 10, h = 8,
            facing = math.random() > 0.5 and 1 or -1,
            speed = 20,
            state = "idle",
            animTimer = math.random() * 0.5,
            animFrame = 1,
            aiTimer = math.random() * 2 + 1,
            aiAction = "idle",
            aiDirX = 0, aiDirY = 0,
            tailTimer = math.random() * 3,
            color = cd.color,
            earInner = cd.earInner,
            legColor = cd.legColor,
            eye = cd.eye,
        })
    end

    -- Dogs (white + black)
    local dogDefs = {
        { color = {0.95, 0.93, 0.9}, earColor = {0.85, 0.8, 0.75}, legColor = {0.88, 0.85, 0.82}, nose = {0.2, 0.15, 0.15}, eye = {0.15, 0.1, 0.05}, x = 80, y = sh / 2 + 30 },
        { color = {0.12, 0.12, 0.12}, earColor = {0.08, 0.06, 0.06}, legColor = {0.08, 0.08, 0.08}, nose = {0.05, 0.03, 0.03}, eye = {0.5, 0.35, 0.15}, x = sw - 60, y = sh / 2 - 10 },
    }
    for _, dd in ipairs(dogDefs) do
        table.insert(dogs, {
            x = dd.x, y = dd.y,
            w = 12, h = 9,
            facing = math.random() > 0.5 and 1 or -1,
            speed = 28,
            state = "idle",
            animTimer = math.random() * 0.5,
            animFrame = 1,
            aiTimer = math.random() * 2 + 1,
            aiAction = "idle",
            aiDirX = 0, aiDirY = 0,
            tailTimer = math.random() * 3,
            color = dd.color,
            earColor = dd.earColor,
            legColor = dd.legColor,
            nose = dd.nose,
            eye = dd.eye,
        })
    end

    -- Generate grass tilemap (random tile variation)
    world.tileSize = 10
    world.tilesX = math.ceil(sw / world.tileSize)
    world.tilesY = math.ceil(sh / world.tileSize)
    world.tiles = {}
    for ty = 1, world.tilesY do
        world.tiles[ty] = {}
        for tx = 1, world.tilesX do
            world.tiles[ty][tx] = math.random(1, 5) -- 5 grass variations
        end
    end

    touchControls.active = {}
end

---------------------------------------------------------------------------
-- COLLISION HELPERS
---------------------------------------------------------------------------
local function rectsOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- Resolve collision: push entity out of table rect
local function resolveTableCollision(ex, ey, ew, eh)
    local t = birthdayTable
    -- Entity foot rect (small area at feet for collision)
    local footH = 6
    local fx, fy = ex, ey - footH
    local fw, fh = ew, footH

    if not rectsOverlap(fx, fy, fw, fh, t.colX, t.colY, t.colW, t.colH) then
        return ex, ey
    end

    -- Push out by smallest overlap
    local overlapLeft   = (fx + fw) - t.colX
    local overlapRight  = (t.colX + t.colW) - fx
    local overlapTop    = (fy + fh) - t.colY
    local overlapBottom = (t.colY + t.colH) - fy

    local minOverlap = math.min(overlapLeft, overlapRight, overlapTop, overlapBottom)

    if minOverlap == overlapLeft then
        ex = t.colX - ew
    elseif minOverlap == overlapRight then
        ex = t.colX + t.colW
    elseif minOverlap == overlapTop then
        ey = t.colY
    else
        ey = t.colY + t.colH + footH
    end

    return ex, ey
end

---------------------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------------------
function love.update(dt)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    -- Player movement (8-directional)
    local mx, my = 0, 0
    if input.left  then mx = mx - 1 end
    if input.right then mx = mx + 1 end
    if input.up    then my = my - 1 end
    if input.down  then my = my + 1 end

    -- Normalize diagonal movement
    if mx ~= 0 and my ~= 0 then
        local inv = 1 / math.sqrt(2)
        mx = mx * inv
        my = my * inv
    end

    player.x = player.x + mx * player.speed * dt
    player.y = player.y + my * player.speed * dt

    -- Clamp to world bounds
    player.x = clamp(player.x, world.minX, world.maxX - player.w)
    player.y = clamp(player.y, world.minY, world.maxY)

    -- Resolve table collision
    player.x, player.y = resolveTableCollision(player.x, player.y, player.w, player.h)

    -- Facing direction
    if mx ~= 0 then player.facing = mx > 0 and 1 or -1 end
    if mx ~= 0 or my ~= 0 then
        player.state = "walk"
        -- Track primary direction
        if math.abs(mx) >= math.abs(my) then
            player.dir = mx > 0 and "right" or "left"
        else
            player.dir = my > 0 and "down" or "up"
        end
    else
        player.state = "idle"
    end

    -- Animation timer
    player.animTimer = player.animTimer + dt
    if player.animTimer >= 0.15 then
        player.animTimer = player.animTimer - 0.15
        player.animFrame = player.animFrame % 4 + 1
    end

    -- Update NPCs (4-directional AI)
    for _, npc in ipairs(npcs) do
        npc.aiTimer = npc.aiTimer - dt
        if npc.aiTimer <= 0 then
            local roll = math.random()
            if roll < 0.35 then
                npc.aiAction = "idle"
                npc.aiDirX = 0
                npc.aiDirY = 0
            else
                npc.aiAction = "walk"
                -- Pick random 2D direction
                local angle = math.random() * math.pi * 2
                npc.aiDirX = math.cos(angle)
                npc.aiDirY = math.sin(angle)
            end
            npc.aiTimer = math.random() * 3 + 1
        end

        if npc.aiAction == "walk" then
            npc.x = npc.x + npc.aiDirX * npc.speed * dt
            npc.y = npc.y + npc.aiDirY * npc.speed * dt
            npc.state = "walk"
            if npc.aiDirX ~= 0 then
                npc.facing = npc.aiDirX > 0 and 1 or -1
            end
            if math.abs(npc.aiDirX) >= math.abs(npc.aiDirY) then
                npc.dir = npc.aiDirX > 0 and "right" or "left"
            else
                npc.dir = npc.aiDirY > 0 and "down" or "up"
            end
        else
            npc.state = "idle"
        end

        -- Clamp + bounce off edges
        if npc.x < world.minX then npc.x = world.minX; npc.aiDirX = math.abs(npc.aiDirX) end
        if npc.x + npc.w > world.maxX then npc.x = world.maxX - npc.w; npc.aiDirX = -math.abs(npc.aiDirX) end
        if npc.y < world.minY then npc.y = world.minY; npc.aiDirY = math.abs(npc.aiDirY) end
        if npc.y > world.maxY then npc.y = world.maxY; npc.aiDirY = -math.abs(npc.aiDirY) end

        -- Table collision for NPCs
        npc.x, npc.y = resolveTableCollision(npc.x, npc.y, npc.w, npc.h)

        npc.animTimer = npc.animTimer + dt
        if npc.animTimer >= 0.15 then
            npc.animTimer = npc.animTimer - 0.15
            npc.animFrame = npc.animFrame % 4 + 1
        end

        if npc.birthday then
            npc.blowerTimer = npc.blowerTimer + dt
        end
    end

    -- Update cats (2D wander AI)
    for _, c in ipairs(cats) do
        c.aiTimer = c.aiTimer - dt
        if c.aiTimer <= 0 then
            local roll = math.random()
            if roll < 0.45 then
                c.aiAction = "idle"
                c.aiDirX = 0
                c.aiDirY = 0
            else
                c.aiAction = "walk"
                local angle = math.random() * math.pi * 2
                c.aiDirX = math.cos(angle)
                c.aiDirY = math.sin(angle)
            end
            c.aiTimer = math.random() * 2 + 1
        end

        if c.aiAction == "walk" then
            c.x = c.x + c.aiDirX * c.speed * dt
            c.y = c.y + c.aiDirY * c.speed * dt
            c.state = "walk"
            if c.aiDirX ~= 0 then
                c.facing = c.aiDirX > 0 and 1 or -1
            end
        else
            c.state = "idle"
        end

        if c.x < world.minX then c.x = world.minX; c.aiDirX = math.abs(c.aiDirX) end
        if c.x + c.w > world.maxX then c.x = world.maxX - c.w; c.aiDirX = -math.abs(c.aiDirX) end
        if c.y < world.minY then c.y = world.minY; c.aiDirY = math.abs(c.aiDirY) end
        if c.y > world.maxY then c.y = world.maxY; c.aiDirY = -math.abs(c.aiDirY) end

        c.x, c.y = resolveTableCollision(c.x, c.y, c.w, c.h)

        c.tailTimer = c.tailTimer + dt
        c.animTimer = c.animTimer + dt
        if c.animTimer >= 0.2 then
            c.animTimer = c.animTimer - 0.2
            c.animFrame = c.animFrame % 2 + 1
        end
    end

    -- Update dogs (2D wander AI)
    for _, d in ipairs(dogs) do
        d.aiTimer = d.aiTimer - dt
        if d.aiTimer <= 0 then
            local roll = math.random()
            if roll < 0.4 then
                d.aiAction = "idle"
                d.aiDirX = 0
                d.aiDirY = 0
            else
                d.aiAction = "walk"
                local angle = math.random() * math.pi * 2
                d.aiDirX = math.cos(angle)
                d.aiDirY = math.sin(angle)
            end
            d.aiTimer = math.random() * 2.5 + 1
        end

        if d.aiAction == "walk" then
            d.x = d.x + d.aiDirX * d.speed * dt
            d.y = d.y + d.aiDirY * d.speed * dt
            d.state = "walk"
            if d.aiDirX ~= 0 then
                d.facing = d.aiDirX > 0 and 1 or -1
            end
        else
            d.state = "idle"
        end

        if d.x < world.minX then d.x = world.minX; d.aiDirX = math.abs(d.aiDirX) end
        if d.x + d.w > world.maxX then d.x = world.maxX - d.w; d.aiDirX = -math.abs(d.aiDirX) end
        if d.y < world.minY then d.y = world.minY; d.aiDirY = math.abs(d.aiDirY) end
        if d.y > world.maxY then d.y = world.maxY; d.aiDirY = -math.abs(d.aiDirY) end

        d.x, d.y = resolveTableCollision(d.x, d.y, d.w, d.h)

        d.tailTimer = d.tailTimer + dt
        d.animTimer = d.animTimer + dt
        if d.animTimer >= 0.2 then
            d.animTimer = d.animTimer - 0.2
            d.animFrame = d.animFrame % 2 + 1
        end
    end
end

---------------------------------------------------------------------------
-- DRAW
---------------------------------------------------------------------------
function love.draw()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

    -- Draw grass tilemap
    drawGrass(sw, sh)

    -- Collect all entities for Y-sorting
    local entities = {}

    -- Table (sort by its bottom Y)
    table.insert(entities, { type = "table", y = birthdayTable.y })

    -- Cats
    for i, c in ipairs(cats) do
        table.insert(entities, { type = "cat", index = i, y = c.y })
    end

    -- Dogs
    for i, d in ipairs(dogs) do
        table.insert(entities, { type = "dog", index = i, y = d.y })
    end

    -- NPCs
    for i, npc in ipairs(npcs) do
        table.insert(entities, { type = "npc", index = i, y = npc.y })
    end

    -- Player
    table.insert(entities, { type = "player", y = player.y })

    -- Sort by Y (lower Y = further back = drawn first)
    table.sort(entities, function(a, b) return a.y < b.y end)

    -- Draw all entities in sorted order
    for _, e in ipairs(entities) do
        if e.type == "table" then
            drawBirthdayTable()
        elseif e.type == "cat" then
            drawCat(cats[e.index])
        elseif e.type == "dog" then
            drawDog(dogs[e.index])
        elseif e.type == "npc" then
            drawPerson(npcs[e.index])
        elseif e.type == "player" then
            drawPerson({
                x = player.x, y = player.y, w = player.w, h = player.h,
                facing = player.facing, dir = player.dir,
                state = player.state, animFrame = player.animFrame,
                palette = { body = {0.2, 0.5, 0.9}, skin = {1, 0.85, 0.7}, legs = {0.3, 0.3, 0.6} },
                gender = "boy", birthday = false,
            })
        end
    end

    -- HUD
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("WASD", 4, 2)
end

---------------------------------------------------------------------------
-- GRASS TILEMAP
---------------------------------------------------------------------------
function drawGrass(sw, sh)
    local ts = world.tileSize
    for ty = 1, world.tilesY do
        for tx = 1, world.tilesX do
            local v = world.tiles[ty][tx]
            local px = (tx - 1) * ts
            local py = (ty - 1) * ts

            -- Base grass color with slight variation
            if v == 1 then
                love.graphics.setColor(0.28, 0.65, 0.28)
            elseif v == 2 then
                love.graphics.setColor(0.32, 0.70, 0.30)
            elseif v == 3 then
                love.graphics.setColor(0.26, 0.62, 0.26)
            elseif v == 4 then
                love.graphics.setColor(0.30, 0.68, 0.32)
            else
                love.graphics.setColor(0.34, 0.72, 0.28)
            end
            love.graphics.rectangle("fill", px, py, ts, ts)

            -- Occasional grass detail
            if v == 1 or v == 5 then
                love.graphics.setColor(0.22, 0.55, 0.22, 0.5)
                love.graphics.rectangle("fill", px + 2, py + 3, 2, 1)
                love.graphics.rectangle("fill", px + 6, py + 7, 2, 1)
            end
            if v == 3 then
                love.graphics.setColor(0.36, 0.75, 0.36, 0.4)
                love.graphics.rectangle("fill", px + 4, py + 1, 1, 2)
            end
        end
    end

    -- Subtle path (lighter strip) near center
    love.graphics.setColor(0.38, 0.60, 0.30, 0.3)
    love.graphics.rectangle("fill", 0, sh / 2 - 15, sw, 30)
end

---------------------------------------------------------------------------
-- BIRTHDAY TABLE WITH CAKE (top-down)
---------------------------------------------------------------------------
function drawBirthdayTable()
    local tx = birthdayTable.x
    local ty = birthdayTable.y

    -- Table shadow
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.ellipse("fill", tx + 22, ty + 4, 26, 8)

    -- Table top (oval-ish for top-down perspective)
    love.graphics.setColor(0.6, 0.35, 0.15)
    love.graphics.rectangle("fill", tx, ty - 17, 44, 20, 3, 3)

    -- Tablecloth stripes
    love.graphics.setColor(1, 0.3, 0.3, 0.45)
    for i = 0, 4 do
        love.graphics.rectangle("fill", tx + i * 9, ty - 17, 5, 20)
    end

    -- Table edge highlight
    love.graphics.setColor(0.5, 0.28, 0.1)
    love.graphics.rectangle("fill", tx, ty + 1, 44, 3, 2, 2)

    -- Cake bottom layer
    local cakeX = tx + 10
    local cakeY = ty - 10

    love.graphics.setColor(0.9, 0.75, 0.5)
    love.graphics.rectangle("fill", cakeX, cakeY - 11, 20, 7)

    -- Frosting stripe
    love.graphics.setColor(1, 0.4, 0.6)
    love.graphics.rectangle("fill", cakeX, cakeY - 12, 20, 2)

    -- Top layer
    love.graphics.setColor(0.95, 0.8, 0.55)
    love.graphics.rectangle("fill", cakeX + 3, cakeY - 18, 14, 7)

    -- Top frosting
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", cakeX + 3, cakeY - 19, 14, 2)

    -- Candles
    local candleColors = {{1,0.2,0.2}, {0.2,0.8,0.2}, {0.2,0.4,1}, {1,0.8,0.1}, {0.8,0.2,0.8}}
    for i = 0, 4 do
        local cc = candleColors[i + 1]
        local cx = cakeX + 5 + i * 2.5
        local cy = cakeY - 19

        love.graphics.setColor(cc)
        love.graphics.rectangle("fill", cx, cy - 5, 1.5, 5)

        -- Flame
        local flicker = math.sin(love.timer.getTime() * 8 + i * 2) * 0.8
        love.graphics.setColor(1, 0.9, 0.2)
        love.graphics.circle("fill", cx + 0.75, cy - 6 + flicker, 1.3)
        love.graphics.setColor(1, 0.6, 0.1)
        love.graphics.circle("fill", cx + 0.75, cy - 6.5 + flicker, 0.8)
    end

end

---------------------------------------------------------------------------
-- CAT (top-down RPG, parameterized colors)
---------------------------------------------------------------------------
function drawCat(c)
    local cx = c.x
    local cy = c.y
    local f = c.facing
    local col = c.color

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.ellipse("fill", cx + c.w / 2, cy + 1, 5, 2)

    love.graphics.push()
    love.graphics.translate(cx + c.w / 2, cy)
    love.graphics.scale(f, 1)
    love.graphics.translate(-c.w / 2, 0)

    -- Body
    love.graphics.setColor(col)
    love.graphics.rectangle("fill", 1, -5, 8, 5)

    -- Head
    love.graphics.setColor(col)
    love.graphics.rectangle("fill", 7, -9, 5, 5)

    -- Ears
    love.graphics.setColor(col)
    love.graphics.polygon("fill", 7.5, -9, 8.5, -12, 9.5, -9)
    love.graphics.polygon("fill", 10.5, -9, 11.5, -12, 12.5, -9)

    -- Inner ears
    love.graphics.setColor(c.earInner)
    love.graphics.polygon("fill", 8, -9, 8.5, -11, 9, -9)
    love.graphics.polygon("fill", 11, -9, 11.5, -11, 12, -9)

    -- Eyes
    love.graphics.setColor(c.eye)
    love.graphics.circle("fill", 9, -7, 0.8)
    love.graphics.circle("fill", 11, -7, 0.8)

    -- Nose
    love.graphics.setColor(1, 0.5, 0.5)
    love.graphics.rectangle("fill", 9.5, -5.5, 1, 0.8)

    -- Legs
    love.graphics.setColor(c.legColor)
    local legAnim = 0
    if c.state == "walk" then
        legAnim = math.sin(love.timer.getTime() * 12) * 1
    end
    love.graphics.rectangle("fill", 2, 0, 1.5, 2 - legAnim)
    love.graphics.rectangle("fill", 5, 0, 1.5, 2 + legAnim)
    love.graphics.rectangle("fill", 7, 0, 1.5, 2 + legAnim)

    -- Tail
    love.graphics.setColor(col)
    local tailWave = math.sin(c.tailTimer * 3) * 2.5
    love.graphics.setLineWidth(1)
    love.graphics.line(1, -4, -2, -7 + tailWave, -1, -10 + tailWave * 0.5)

    love.graphics.pop()
end

---------------------------------------------------------------------------
-- DOG (top-down RPG, ~12x9 px)
---------------------------------------------------------------------------
function drawDog(d)
    local dx = d.x
    local dy = d.y
    local f = d.facing
    local col = d.color

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.ellipse("fill", dx + d.w / 2, dy + 1, 6, 2.5)

    love.graphics.push()
    love.graphics.translate(dx + d.w / 2, dy)
    love.graphics.scale(f, 1)
    love.graphics.translate(-d.w / 2, 0)

    -- Body (slightly bigger than cat)
    love.graphics.setColor(col)
    love.graphics.rectangle("fill", 1, -6, 9, 6)

    -- Head
    love.graphics.setColor(col)
    love.graphics.rectangle("fill", 8, -10, 6, 6)

    -- Snout
    love.graphics.setColor(col[1] * 0.95 + 0.05, col[2] * 0.95 + 0.05, col[3] * 0.95 + 0.05)
    love.graphics.rectangle("fill", 13, -8, 3, 3)

    -- Nose
    love.graphics.setColor(d.nose)
    love.graphics.rectangle("fill", 15, -7.5, 1.5, 1.5)

    -- Floppy ears (rounded rectangles hanging down)
    love.graphics.setColor(d.earColor)
    love.graphics.rectangle("fill", 8, -10, 2.5, 7, 1, 1)
    love.graphics.rectangle("fill", 12, -10, 2.5, 7, 1, 1)

    -- Eyes
    love.graphics.setColor(d.eye)
    love.graphics.circle("fill", 10, -8, 0.9)
    love.graphics.circle("fill", 12.5, -8, 0.9)

    -- Mouth line
    love.graphics.setColor(d.nose)
    love.graphics.setLineWidth(0.5)
    love.graphics.line(14, -5.5, 15.5, -5)

    -- Legs (4 legs, animated)
    love.graphics.setColor(d.legColor)
    local legAnim = 0
    if d.state == "walk" then
        legAnim = math.sin(love.timer.getTime() * 10) * 1.2
    end
    love.graphics.rectangle("fill", 2, 0, 2, 2.5 - legAnim)
    love.graphics.rectangle("fill", 5, 0, 2, 2.5 + legAnim)
    love.graphics.rectangle("fill", 7, 0, 2, 2.5 + legAnim)
    love.graphics.rectangle("fill", 9, 0, 2, 2.5 - legAnim)

    -- Tail (wagging, curls up)
    love.graphics.setColor(col)
    local tailWag = math.sin(d.tailTimer * 5) * 2
    love.graphics.setLineWidth(1.5)
    love.graphics.line(1, -4, -1, -6 + tailWag, -2, -9 + tailWag * 0.5)

    love.graphics.pop()
end

---------------------------------------------------------------------------
-- PERSON (top-down RPG — ~14x22 px characters)
---------------------------------------------------------------------------
function drawPerson(p)
    local bodyColor = p.palette.body
    local skinColor = p.palette.skin
    local legColor  = p.palette.legs

    local cx = p.x
    local cy = p.y - p.h

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.ellipse("fill", cx + p.w / 2, p.y + 1, 6, 2.5)

    love.graphics.push()
    love.graphics.translate(cx + p.w / 2, cy)
    love.graphics.scale(p.facing, 1)
    love.graphics.translate(-p.w / 2, 0)

    -- Birthday hat
    if p.birthday then
        love.graphics.setColor(1, 0.85, 0)
        love.graphics.polygon("fill", 4, 0, 10, 0, 7, -10)
        -- Stripe
        love.graphics.setColor(1, 0.2, 0.3)
        love.graphics.polygon("fill", 5, -2, 9, -2, 8, -6, 6, -6)
        -- Pom pom
        love.graphics.setColor(1, 0.3, 0.8)
        love.graphics.circle("fill", 7, -10, 1.5)
    end

    -- Hair (girls)
    if p.gender == "girl" then
        local hairColor = p.hair or {0.3, 0.15, 0.05}
        love.graphics.setColor(hairColor)
        love.graphics.rectangle("fill", 2, -1, 10, 11)
        love.graphics.rectangle("fill", 3, -2, 8, 2)
    end

    -- Head
    love.graphics.setColor(skinColor)
    love.graphics.rectangle("fill", 3, 0, 8, 8)

    -- Hair bangs (girls)
    if p.gender == "girl" then
        local hairColor = p.hair or {0.3, 0.15, 0.05}
        love.graphics.setColor(hairColor)
        love.graphics.rectangle("fill", 3, -1, 8, 3)
    end

    -- Eyes
    love.graphics.setColor(0.1, 0.1, 0.1)
    local eyeBlink = (p.animFrame == 4 and p.state == "idle") and 1 or 2
    love.graphics.rectangle("fill", 6, 2, 1.5, eyeBlink)
    love.graphics.rectangle("fill", 9, 2, 1.5, eyeBlink)

    -- Eyelashes for girls
    if p.gender == "girl" and eyeBlink > 1 then
        love.graphics.setLineWidth(0.5)
        love.graphics.line(6, 2, 5.5, 1.5)
        love.graphics.line(7.5, 2, 8, 1.5)
        love.graphics.line(9, 2, 8.5, 1.5)
        love.graphics.line(10.5, 2, 11, 1.5)
    end

    -- Mouth
    love.graphics.setColor(0.8, 0.3, 0.3)
    if p.birthday then
        love.graphics.setLineWidth(0.5)
        love.graphics.arc("line", 8, 5.5, 2, 0, math.pi)
    else
        love.graphics.rectangle("fill", 7, 5.5, 3, 1)
    end

    -- Body / dress
    love.graphics.setColor(bodyColor)
    if p.gender == "girl" then
        love.graphics.rectangle("fill", 3, 8, 8, 5)
        love.graphics.polygon("fill", 1, 13, 3, 8, 11, 8, 13, 13)
        love.graphics.rectangle("fill", 1, 13, 12, 3)
    else
        love.graphics.rectangle("fill", 3, 8, 8, 10)
    end

    -- Legs
    love.graphics.setColor(legColor)
    local legOffset = 0
    if p.state == "walk" then
        legOffset = math.sin(love.timer.getTime() * 10) * 2
    end
    if p.gender == "girl" then
        love.graphics.rectangle("fill", 4, 16, 2, 6 - legOffset)
        love.graphics.rectangle("fill", 8, 16, 2, 6 + legOffset)
    else
        love.graphics.rectangle("fill", 3, 18, 3, 4 - legOffset)
        love.graphics.rectangle("fill", 8, 18, 3, 4 + legOffset)
    end

    -- Arms
    love.graphics.setColor(skinColor)
    local armSwing = 0
    if p.state == "walk" then
        armSwing = math.sin(love.timer.getTime() * 10) * 3
    end

    if p.birthday then
        -- Back arm
        love.graphics.rectangle("fill", 0, 9, 3, 6 - armSwing)
        -- Front arm raised
        love.graphics.rectangle("fill", 11, 7, 3, 4)

        -- Lingua de sogra
        love.graphics.push()
        love.graphics.translate(14, 7)

        -- Mouthpiece
        love.graphics.setColor(0.9, 0.1, 0.2)
        love.graphics.rectangle("fill", 0, 0, 3, 2)

        -- Tube
        local blowPhase = math.sin(love.timer.getTime() * 4) * 0.5 + 0.5
        local tubeLen = 7 + blowPhase * 10

        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.rectangle("fill", 3, 0.2, tubeLen, 1.5)

        -- Stripes
        love.graphics.setColor(1, 0.85, 0)
        for s = 0, tubeLen - 2, 3 do
            love.graphics.rectangle("fill", 3 + s, 0.2, 1.5, 1.5)
        end

        -- Curly tip
        local tipX = 3 + tubeLen
        local tipWave = math.sin(love.timer.getTime() * 6) * 1.5
        love.graphics.setColor(0.9, 0.1, 0.2)
        love.graphics.circle("fill", tipX, 1 + tipWave, 1.5)

        love.graphics.pop()
    else
        love.graphics.rectangle("fill", 0, 9, 3, 6 + armSwing)
        love.graphics.rectangle("fill", 11, 9, 3, 6 - armSwing)
    end

    love.graphics.pop()
end

---------------------------------------------------------------------------
-- TOUCH DIRECTION HELPER
-- Splits the screen into 4 zones by diagonals from center:
-- touch closer to left edge = left, right edge = right, etc.
---------------------------------------------------------------------------
local function touchDirection(x, y)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local cx, cy = sw / 2, sh / 2
    local dx = x - cx
    local dy = y - cy
    -- Normalize dy to account for aspect ratio
    local aspect = sw / sh
    if math.abs(dx) > math.abs(dy * aspect) then
        return dx > 0 and "right" or "left"
    else
        return dy > 0 and "down" or "up"
    end
end

local function applyTouchDir(dir)
    input.left  = (dir == "left")
    input.right = (dir == "right")
    input.up    = (dir == "up")
    input.down  = (dir == "down")
end

---------------------------------------------------------------------------
-- KEYBOARD INPUT
---------------------------------------------------------------------------
function love.keypressed(key)
    if key == "left"  or key == "a" then input.left  = true end
    if key == "right" or key == "d" then input.right = true end
    if key == "up"    or key == "w" then input.up    = true end
    if key == "down"  or key == "s" then input.down  = true end
    if key == "escape" then love.event.quit() end
end

function love.keyreleased(key)
    if key == "left"  or key == "a" then input.left  = false end
    if key == "right" or key == "d" then input.right = false end
    if key == "up"    or key == "w" then input.up    = false end
    if key == "down"  or key == "s" then input.down  = false end
end

---------------------------------------------------------------------------
-- TOUCH INPUT (invisible zones — diagonal split from center)
---------------------------------------------------------------------------
function love.touchpressed(id, x, y)
    local dir = touchDirection(x, y)
    touchControls.active[id] = dir
    applyTouchDir(dir)
end

function love.touchreleased(id)
    touchControls.active[id] = nil
    -- Check if any other touch is still active
    local remaining = nil
    for _, d in pairs(touchControls.active) do remaining = d; break end
    if remaining then
        applyTouchDir(remaining)
    else
        input.left = false; input.right = false
        input.up = false; input.down = false
    end
end

function love.touchmoved(id, x, y)
    local dir = touchDirection(x, y)
    touchControls.active[id] = dir
    applyTouchDir(dir)
end

---------------------------------------------------------------------------
-- MOUSE (web fallback — same diagonal zones)
---------------------------------------------------------------------------
function love.mousepressed(x, y, button)
    if button == 1 then
        local dir = touchDirection(x, y)
        touchControls.active["mouse"] = dir
        applyTouchDir(dir)
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        touchControls.active["mouse"] = nil
        input.left = false; input.right = false
        input.up = false; input.down = false
    end
end
