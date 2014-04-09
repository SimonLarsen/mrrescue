function love.conf(t)
    t.title = "Mr. Rescue"        
    t.author = "Tangram Games"        
    t.url = "http://tangramgames.dk"
    t.identity = "mrrescue"
    t.version = "0.9.0"         
    t.console = false           
    t.release = true
    t.window.width = 256*3
    t.window.height = 200*3
    t.window.fullscreen = false
    t.window.vsync = true       
    t.window.fsaa = 0           
    t.modules.mouse = false      
    t.modules.physics = false
end
