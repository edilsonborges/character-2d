function love.conf(t)
    t.identity = "character2d"
    t.version = "11.5"

    t.window.title = "Character 2D"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true

    t.modules.joystick = true
    t.modules.touch = true
end
