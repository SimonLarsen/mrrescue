require("config")
require("resources")
require("util")
require("map")
require("player")
require("human")
require("enemy")
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
require("levelselection")

WIDTH = 256
HEIGHT = 200
MAPW = 41*16
MAPH = 16*16
show_debug = false

local MIN_FRAMERATE = 1/15
local MAX_FRAMERATE = 1/120
LAST_SECTION = 40

STATE_SPLASH, STATE_INGAME, STATE_MAINMENU, STATE_LEVELSELECTION, STATE_OPTIONS = 0,1,2,3,4

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

	if state == STATE_INGAME then
		ingame.update(dt)
	elseif state == STATE_SPLASH then
		splash.update(dt)
	end
end

function love.draw()
	if state == STATE_INGAME then
		ingame.draw()
	elseif state == STATE_MAINMENU then
		mainmenu.draw()
	elseif state == STATE_SPLASH then
		splash.draw()
	elseif state == STATE_OPTIONS then
		options.draw()
	elseif state == STATE_LEVELSELECTION then
		levelselection.draw()
	end
end

function love.keypressed(k, uni)
	if k == "escape" then
		love.event.quit()
	end

	if state == STATE_INGAME then
		ingame.keypressed(k, uni)
	elseif state == STATE_MAINMENU then
		mainmenu.keypressed(k, uni)
	elseif state == STATE_LEVELSELECTION then
		levelselection.keypressed(k, uni)
	elseif state == STATE_OPTIONS then
		options.keypressed(k, uni)
	elseif state == STATE_SPLASH then
		splash.keypressed(k, uni)
	end
end

function love.joystickpressed(joy, k)
	if state == STATE_INGAME then
		ingame.joystickpressed(joy, k)
	elseif state == STATE_MAINMENU then
		mainmenu.joystickpressed(joy, k)
	elseif state == STATE_LEVELSELECTION then
		levelselection.joystickpressed(joy, k)
	elseif state == STATE_OPTIONS then
		options.joystickpressed(joy, k)
	elseif state == STATE_SPLASH then
		splash.joystickpressed(joy, k)
	end
end
