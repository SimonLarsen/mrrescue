function love.conf(t)
    t.title = "Firefighter"        
    t.author = "Simon Larsen"        
    t.url = nil                 
    t.identity = nil            
    t.version = "0.8.0"         
    t.console = false           
    t.release = false           
    t.screen.width = 256*3
    t.screen.height = 200*3
    t.screen.fullscreen = false 
    t.screen.vsync = true       
    t.screen.fsaa = 0           
    t.modules.mouse = false      
    t.modules.physics = false
end
