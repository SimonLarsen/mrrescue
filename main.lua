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
require("howto")

WIDTH = 256
HEIGHT = 200
MAPW = 41*16
MAPH = 16*16
show_debug = false

local MIN_FRAMERATE = 1/15
local MAX_FRAMERATE = 1/120

STATE_SPLASH, STATE_INGAME, STATE_MAINMENU, STATE_LEVELSELECTION, STATE_OPTIONS, STATE_KEYBOARD, STATE_JOYSTICK, STATE_HOWTO = 0,1,2,3,4,5,6,7
gamestates = {[0]=splash, [1]=ingame, [2]=mainmenu, [3]=levelselection, [4]=options, [5]=keyboard, [6]=joystick, [7]=howto}

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
	gamestates[state].keypressed(k, uni)
end

function love.joystickpressed(joy, k)
	if joy == config.joystick then
		gamestates[state].joystickpressed(joy, k)
	end
end

--- Updates keystates of ingame keys.
--  Should only be called when ingame, as it
--  makes call to Player
function updateKeys()
	-- Check keyboard keys
	for action, key in pairs(config.keys) do
		if love.keyboard.isDown(key) then
			keystate[action] = true
		else
			keystate[action] = false
		end
	end

	-- Check joystick axes
	local axis1, axis2 = love.joystick.getAxes(config.joystick)
	if axis1 and axis2 then
		if axis1 < -0.5 then
			keystate.left = true
		elseif axis1 > 0.5 then
			keystate.right = true
		end
		if axis2 < -0.5 then
			keystate.up = true
		elseif axis2 > 0.5 then
			keystate.down = true
		end
		-- Check sudden movements (for ladders)
		if math.abs(keystate.oldaxis1) < 0.05 then
			if axis1 < -0.5 then
				gamestates[state].action("left")
			elseif axis1 > 0.5 then
				gamestates[state].action("right")
			end
		end
		if math.abs(keystate.oldaxis2) < 0.05 then
			if axis2 < -0.5 then
				gamestates[state].action("up")
			elseif axis2 > 0.5 then
				gamestates[state].action("down")
			end
		end
		-- Write axis values for next update
		keystate.oldaxis1 = axis1 or 0
		keystate.oldaxis2 = axis2 or 0
	end

	-- Check joystick keys
	for action, key in pairs(config.joykeys) do
		if love.joystick.isDown(config.joystick, key) then
			keystate[action] = true
		end
	end
end
