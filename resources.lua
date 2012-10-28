img = {} -- list of Image objects
quad = {}

function loadImages()
	img.player_running = love.graphics.newImage("data/player_running.png")
	quad.player_idle = love.graphics.newQuad(45,0,15,22, 64,32)
end
