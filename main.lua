require("AnAL")
require("resources")
require("map")
require("player")
require("water")
require("door")

WIDTH = 256
HEIGHT = 200
MAPW = 41*16
MAPH = 16*16
translate_x, translate_y = 0,0

local SCALE = 3
local FRAMERATE_CAP = 1/15

local lg = love.graphics

function love.load()
	lg.setBackgroundColor(82,117,176)
	lg.setMode(WIDTH*SCALE,HEIGHT*SCALE,false,true)
	lg.setDefaultImageFilter("nearest","nearest")

	loadResources()

	map = Map.create()
	player = Player.create(64,70)
end

function love.update(dt)
	-- Cap framerate
	if dt > FRAMERATE_CAP then dt = FRAMERATE_CAP end

	-- Update entities
	player:update(dt)
end

function love.draw()
	-- Scale screen
	lg.scale(SCALE,SCALE)
	-- Calculate translation offest
	translate_x = math.min(math.max(0, player.x-WIDTH/2), MAPW-WIDTH)
	translate_y = math.min(math.max(0, player.y-11-HEIGHT/2), MAPH-HEIGHT)
	lg.translate(-math.floor(translate_x), -math.floor(translate_y))

	-- Draw map
	map:draw()

	-- Draw player
	player:draw()
end

function love.keypressed(k, uni)
	if k == "escape" then
		love.event.quit()
	else
		player:keypressed(k)
	end
end
