-- Character 2D — a simple animated character demo
-- Targets: macOS desktop, iOS, and web (via love.js)

local character = {}
local world = {}
local input = {}
local touchControls = {}

-- Detect platform
local isMobile = love.system.getOS() == "iOS" or love.system.getOS() == "Android"

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- World / ground
    world.gravity = 800
    world.groundY = love.graphics.getHeight() - 80

    -- Character state
    character.x = 200
    character.y = world.groundY
    character.w = 32
    character.h = 48
    character.vx = 0
    character.vy = 0
    character.speed = 200
    character.jumpForce = -400
    character.onGround = true
    character.facing = 1 -- 1 = right, -1 = left
    character.animTimer = 0
    character.animFrame = 1
    character.state = "idle" -- idle, walk, jump

    -- Input state
    input.left = false
    input.right = false
    input.jump = false

    -- Touch controls (for mobile / web touch)
    touchControls.buttons = {
        left  = { x = 20,  y = love.graphics.getHeight() - 100, w = 70, h = 70 },
        right = { x = 100, y = love.graphics.getHeight() - 100, w = 70, h = 70 },
        jump  = { x = love.graphics.getWidth() - 90, y = love.graphics.getHeight() - 100, w = 70, h = 70 },
    }
    touchControls.active = {} -- touch id -> button name
end

function love.resize(w, h)
    world.groundY = h - 80
    touchControls.buttons.left.y  = h - 100
    touchControls.buttons.right.y = h - 100
    touchControls.buttons.jump.y  = h - 100
    touchControls.buttons.jump.x  = w - 90
end

---------------------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------------------
function love.update(dt)
    -- Resolve input
    local moveX = 0
    if input.left  then moveX = moveX - 1 end
    if input.right then moveX = moveX + 1 end

    character.vx = moveX * character.speed

    if moveX ~= 0 then
        character.facing = moveX
    end

    -- Jump
    if input.jump and character.onGround then
        character.vy = character.jumpForce
        character.onGround = false
        input.jump = false -- consume
    end

    -- Gravity
    if not character.onGround then
        character.vy = character.vy + world.gravity * dt
    end

    -- Move
    character.x = character.x + character.vx * dt
    character.y = character.y + character.vy * dt

    -- Ground collision
    if character.y >= world.groundY then
        character.y = world.groundY
        character.vy = 0
        character.onGround = true
    end

    -- Keep on screen
    local sw = love.graphics.getWidth()
    if character.x < 0 then character.x = 0 end
    if character.x + character.w > sw then character.x = sw - character.w end

    -- Animation state
    if not character.onGround then
        character.state = "jump"
    elseif moveX ~= 0 then
        character.state = "walk"
    else
        character.state = "idle"
    end

    -- Simple frame animation
    character.animTimer = character.animTimer + dt
    if character.animTimer >= 0.15 then
        character.animTimer = character.animTimer - 0.15
        character.animFrame = character.animFrame % 4 + 1
    end
end

---------------------------------------------------------------------------
-- DRAW
---------------------------------------------------------------------------
function love.draw()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

    -- Sky gradient (simple two-color)
    love.graphics.setColor(0.4, 0.7, 1)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Ground
    love.graphics.setColor(0.3, 0.7, 0.3)
    love.graphics.rectangle("fill", 0, world.groundY, sw, sh - world.groundY)

    -- Ground line
    love.graphics.setColor(0.2, 0.5, 0.2)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, world.groundY, sw, world.groundY)

    -- Draw character (pixel-art style, procedural)
    drawCharacter()

    -- Touch controls overlay
    if isMobile or love.touch.getTouches()[1] then
        drawTouchControls()
    end

    -- HUD
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Arrow keys / WASD to move, Space to jump", 10, 10)
    if isMobile then
        love.graphics.print("Use on-screen buttons", 10, 28)
    end
end

---------------------------------------------------------------------------
-- Procedural pixel character
---------------------------------------------------------------------------
function drawCharacter()
    local cx = character.x
    local cy = character.y - character.h
    local f = character.facing
    local s = character.state
    local frame = character.animFrame
    local px = 4 -- pixel size

    love.graphics.push()
    love.graphics.translate(cx + character.w / 2, cy)
    love.graphics.scale(f, 1)
    love.graphics.translate(-character.w / 2, 0)

    -- Body
    love.graphics.setColor(0.2, 0.5, 0.9)
    love.graphics.rectangle("fill", 8, 16, 16, 20)

    -- Head
    love.graphics.setColor(1, 0.85, 0.7)
    love.graphics.rectangle("fill", 8, 0, 16, 16)

    -- Eyes
    love.graphics.setColor(0.1, 0.1, 0.1)
    local eyeBlink = (frame == 4 and s == "idle") and 1 or 3
    love.graphics.rectangle("fill", 16, 5, 3, eyeBlink)
    love.graphics.rectangle("fill", 22, 5, 3, eyeBlink)

    -- Mouth
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.rectangle("fill", 18, 11, 6, 2)

    -- Legs
    love.graphics.setColor(0.3, 0.3, 0.6)
    local legOffset = 0
    if s == "walk" then
        legOffset = math.sin(love.timer.getTime() * 10) * 4
    elseif s == "jump" then
        legOffset = 3
    end
    love.graphics.rectangle("fill", 8,  36, 6, 12 - legOffset)
    love.graphics.rectangle("fill", 18, 36, 6, 12 + legOffset)

    -- Arms
    love.graphics.setColor(1, 0.85, 0.7)
    local armSwing = 0
    if s == "walk" then
        armSwing = math.sin(love.timer.getTime() * 10) * 6
    end
    love.graphics.rectangle("fill", 0,  18, 6, 14 + armSwing)
    love.graphics.rectangle("fill", 26, 18, 6, 14 - armSwing)

    love.graphics.pop()
end

---------------------------------------------------------------------------
-- Touch controls
---------------------------------------------------------------------------
function drawTouchControls()
    love.graphics.setColor(1, 1, 1, 0.3)
    for name, btn in pairs(touchControls.buttons) do
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8, 8)
        love.graphics.setColor(1, 1, 1, 0.7)
        if name == "left" then
            love.graphics.polygon("fill", btn.x + 50, btn.y + 15, btn.x + 50, btn.y + 55, btn.x + 20, btn.y + 35)
        elseif name == "right" then
            love.graphics.polygon("fill", btn.x + 20, btn.y + 15, btn.x + 20, btn.y + 55, btn.x + 50, btn.y + 35)
        elseif name == "jump" then
            love.graphics.polygon("fill", btn.x + 15, btn.y + 50, btn.x + 55, btn.y + 50, btn.x + 35, btn.y + 15)
        end
        love.graphics.setColor(1, 1, 1, 0.3)
    end
end

local function pointInRect(px, py, r)
    return px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

---------------------------------------------------------------------------
-- KEYBOARD INPUT
---------------------------------------------------------------------------
function love.keypressed(key)
    if key == "left"  or key == "a" then input.left  = true end
    if key == "right" or key == "d" then input.right = true end
    if key == "space" or key == "up" or key == "w" then input.jump = true end
    if key == "escape" then love.event.quit() end
end

function love.keyreleased(key)
    if key == "left"  or key == "a" then input.left  = false end
    if key == "right" or key == "d" then input.right = false end
end

---------------------------------------------------------------------------
-- TOUCH INPUT (iOS / Web touch)
---------------------------------------------------------------------------
function love.touchpressed(id, x, y)
    for name, btn in pairs(touchControls.buttons) do
        if pointInRect(x, y, btn) then
            touchControls.active[id] = name
            if name == "left"  then input.left  = true end
            if name == "right" then input.right = true end
            if name == "jump"  then input.jump  = true end
        end
    end
end

function love.touchreleased(id)
    local name = touchControls.active[id]
    if name then
        if name == "left"  then input.left  = false end
        if name == "right" then input.right = false end
        touchControls.active[id] = nil
    end
end

function love.touchmoved(id, x, y)
    local prevName = touchControls.active[id]
    local newName = nil
    for name, btn in pairs(touchControls.buttons) do
        if pointInRect(x, y, btn) then
            newName = name
        end
    end

    if prevName ~= newName then
        -- Release old
        if prevName == "left"  then input.left  = false end
        if prevName == "right" then input.right = false end
        -- Press new
        if newName then
            touchControls.active[id] = newName
            if newName == "left"  then input.left  = true end
            if newName == "right" then input.right = true end
            if newName == "jump"  then input.jump  = true end
        else
            touchControls.active[id] = nil
        end
    end
end

---------------------------------------------------------------------------
-- MOUSE (fallback for web without touch)
---------------------------------------------------------------------------
function love.mousepressed(x, y, button)
    if button == 1 then
        for name, btn in pairs(touchControls.buttons) do
            if pointInRect(x, y, btn) then
                touchControls.active["mouse"] = name
                if name == "left"  then input.left  = true end
                if name == "right" then input.right = true end
                if name == "jump"  then input.jump  = true end
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        local name = touchControls.active["mouse"]
        if name then
            if name == "left"  then input.left  = false end
            if name == "right" then input.right = false end
            touchControls.active["mouse"] = nil
        end
    end
end
