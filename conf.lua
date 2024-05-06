function love.conf(t)
    t.window.title = "Lucerna's Depths"
    t.window.icon = "resources/textures/ui/icon.png"
    t.window.width = 480
    t.window.height = 270
    t.version = "11.5"
    t.window.minwidth = 480
    t.window.minheight = 270

    t.modules.physics = false
    t.modules.touch = false
    t.modules.joystick = false
    t.modules.video = false
end
