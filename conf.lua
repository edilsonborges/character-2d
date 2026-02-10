function love.conf(t)
    t.identity = "character2d"
    t.version = "11.5"

    t.window.title = "Character 2D"
    t.window.width = 340
    t.window.height = 250
    t.window.resizable = false

    t.modules.joystick = true
    t.modules.touch = true
end
