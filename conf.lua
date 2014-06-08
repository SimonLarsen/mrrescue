function love.conf(t)
    t.identity = "mrrescue"
    t.version = "0.9.1"
    t.console = false

    t.window.title = "Mr. Rescue"
    t.window.icon = nil
    t.window.width = 256*3
    t.window.height = 200*3
    t.window.borderless = false
    t.window.resizable = false
    t.window.fullscreen = false
    t.window.fullscreentype = "normal"
    t.window.vsync = true
    t.window.fsaa = 0
    t.window.display = 1
    t.window.highdpi = false
    t.window.srgb = false

    t.modules.physics = false
    t.modules.mouse = false
end
