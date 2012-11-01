img = {}  	-- global Image objects
quad = {}	-- global Quads

function loadResources()
	-- Load images and quads
	img.player_running = love.graphics.newImage("data/player_running.png")
	quad.player_idle = love.graphics.newQuad(45,0,15,22, 64,32)
	quad.player_jump = love.graphics.newQuad(15,0,15,22, 64,32)

	img.player_climb_up = love.graphics.newImage("data/player_climb_up.png")
	img.player_climb_down = love.graphics.newImage("data/player_climb_down.png")

	img.player_gun = love.graphics.newImage("data/gun.png")
	quad.player_gun = {}
	for i=0,4 do
		quad.player_gun[i] = love.graphics.newQuad(i*12,0,12,16, 64,16)
	end

	img.water = love.graphics.newImage("data/water.png")

	img.door = love.graphics.newImage("data/door.png")
	quad.door_closed = love.graphics.newQuad(0,0, 8,48, 64,64)
	quad.door_open   = love.graphics.newQuad(16,0, 25,50, 64,64)
end
