require("AnAL")
require("resources")
require("map")
require("player")
require("door")

WIDTH = 256
HEIGHT = 200
MAPW = 41*16
MAPH = 16*16
translate_x, translate_y = 0,0
show_debug = false

local SCALE = 3
local FRAMERATE_CAP = 1/15

local lg = love.graphics

function love.load()
	lg.setBackgroundColor(82,117,176)
	lg.setMode(WIDTH*SCALE,HEIGHT*SCALE,false,true)
	lg.setDefaultImageFilter("nearest","nearest")

	lg.setFont(lg.newFont(16))

	loadResources()

	map = Map.create()
	player = Player.create(MAPW/2,70)
end

function love.update(dt)
	-- Cap framerate
	if dt > FRAMERATE_CAP then dt = FRAMERATE_CAP end

	-- Update entities
	player:update(dt)
	map:update(dt)
end

function love.draw()
	-- Push untransformed matrix
	lg.push()

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

	lg.pop()
	-- Draw debug information
	if show_debug == true then
		drawDebug()
	end
end

function drawDebug()
	love.graphics.print("Player: ("..player.flx.." , "..player.fly..")",10,10)
end

function love.keypressed(k, uni)
	if k == "escape" then
		love.event.quit()
	elseif k == "f1" then
		show_debug = not show_debug
	else
		player:keypressed(k)
	end
end
