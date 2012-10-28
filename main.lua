require("AnAL")
require("resources")
require("map")
require("player")

WIDTH = 256
HEIGHT = 200
SCALE = 3
MAPW = 41*16
MAPH = 16*16

local lg = love.graphics
local translate_x, translate_y

function love.load()
	lg.setBackgroundColor(82,117,176)
	lg.setMode(WIDTH*SCALE,HEIGHT*SCALE,false,true)
	lg.setDefaultImageFilter("nearest","nearest")

	loadImages()

	map = Map.create()
	player = Player.create(64,80)
end

function love.update(dt)
	player:update(dt)
end

function love.draw()
	lg.scale(SCALE,SCALE)
	translate_x = math.min(math.max(0, player.x-WIDTH/2), MAPW-WIDTH)
	translate_y = math.min(math.max(0, player.y-11-HEIGHT/2), MAPH-HEIGHT)
	lg.translate(-math.floor(translate_x), -math.floor(translate_y))

	map:draw()
	player:draw()
end

function love.keypressed(k, uni)
	player:keypressed(k)
end
