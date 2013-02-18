require("config")
require("resources")
require("util")
require("map")
require("player")
require("human")
require("enemy")
require("boss")
require("door")
require("item")
require("fire")
require("particles")
-- 3rd party libraries
require("AnAL")
require("slam")
require("TSerial")
-- gamestates
require("splash")
require("mainmenu")
require("ingame")
require("options")
require("keyboard")
require("joystick")
require("levelselection")

WIDTH = 256
HEIGHT = 200
MAPW = 41*16
MAPH = 16*16
show_debug = false

local MIN_FRAMERATE = 1/15
local MAX_FRAMERATE = 1/120

STATE_SPLASH, STATE_INGAME, STATE_MAINMENU, STATE_LEVELSELECTION, STATE_OPTIONS, STATE_KEYBOARD, STATE_JOYSTICK = 0,1,2,3,4,5,6
gamestates = {[0]=splash, [1]=ingame, [2]=mainmenu, [3]=levelselection, [4]=options, [5]=keyboard, [6]=joystick}

function love.load()
	loadConfig()

	love.graphics.setBackgroundColor(0,0,0)
	love.graphics.setMode(WIDTH*config.scale, HEIGHT*config.scale, false, config.vsync)
	love.graphics.setDefaultImageFilter("nearest","nearest")
	loadResources()

	splash.enter()
end

function love.update(dt)
	-- Cap framerate
	if dt > MIN_FRAMERATE then dt = MIN_FRAMERATE end
	if dt < MAX_FRAMERATE then
		love.timer.sleep(MAX_FRAMERATE - dt)
		dt = MAX_FRAMERATE
	end

	gamestates[state].update(dt)
end

function love.draw()
	gamestates[state].draw()
end

function love.keypressed(k, uni)
	if k == "escape" then
		love.event.quit()
	end

	gamestates[state].keypressed(k, uni)
end

function love.joystickpressed(joy, k)
	gamestates[state].joystickpressed(joy, k)
end
