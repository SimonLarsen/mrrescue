require("config")
require("resources")
require("util")
require("map")
require("player")
require("human")
require("enemy")
require("boss")
require("magmahulk")
require("gasleak")
require("gasghost")
require("charcoal")
require("coalball")
require("door")
require("item")
require("fire")
require("particles")
-- gamestates
require("splash")
require("mainmenu")
require("ingame")
require("ingame_menu")
require("options")
require("keyboard")
require("joystick")
require("levelselection")
require("summary")
require("highscore_entry")
require("highscore_list")
require("howto")
require("history")
-- 3rd party libraries
require("AnAL")
require("slam")
require("TSerial")

WIDTH = 256
HEIGHT = 200
MAPW = 41*16
MAPH = 16*16
show_debug = false

local MAX_FRAMETIME = 1/15
local MIN_FRAMETIME = 1/120

STATE_SPLASH, STATE_INGAME, STATE_MAINMENU, STATE_LEVELSELECTION, STATE_OPTIONS, STATE_KEYBOARD, STATE_JOYSTICK,
STATE_HOWTO, STATE_HIGHSCORE_LIST, STATE_HIGHSCORE_ENTRY, STATE_INGAME_MENU, STATE_HISTORY, STATE_SUMMARY = 0,1,2,3,4,5,6,7,8,9,10,11,12

gamestates = {[0]=splash, [1]=ingame, [2]=mainmenu, [3]=levelselection, [4]=options, [5]=keyboard,
[6]=joystick, [7]=howto, [8]=highscore_list, [9]=highscore_entry, [10]=ingame_menu, [11]=history, [12]=summary}

function love.load()
	loadConfig()
	loadHighscores()
	loadStats()

	love.graphics.setBackgroundColor(0,0,0)
	love.graphics.setMode(WIDTH*config.scale, HEIGHT*config.scale, false, config.vsync)
	love.graphics.setDefaultImageFilter("nearest","nearest")
	loadResources()

	splash.enter()
end

function love.update(dt)
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
		if gamestates[state].joystickpressed then
			gamestates[state].joystickpressed(joy, k)
		else
			for a, key in pairs(config.joykeys) do
				if k == key then
					gamestates[state].action(a)
				end
			end
		end
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

function love.run()
    math.randomseed(os.time())
    math.random() math.random()
    if love.load then love.load(arg) end
    local dt = 0

    -- Main loop time.
    while true do
		local frame_start = love.timer.getMicroTime()
        -- Process events.
        if love.event then
            love.event.pump()
            for e,a,b,c,d in love.event.poll() do
                if e == "quit" then
                    if not love.quit or not love.quit() then
                        if love.audio then
                            love.audio.stop()
                        end
                        return
                    end
                end
                love.handlers[e](a,b,c,d)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
			dt = cap(dt, MIN_FRAMETIME, MAX_FRAMETIME)
        end

        -- Call update and draw
        if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
        if love.graphics then
            love.graphics.clear()
            if love.draw then love.draw() end
        end

		-- Update screen
        if love.graphics then love.graphics.present() end

		-- Sleep to compensate for framerate cap
		local elapsed_time = love.timer.getMicroTime() - frame_start
		if elapsed_time < MIN_FRAMETIME then
			love.timer.sleep(MIN_FRAMETIME - elapsed_time)
		end
    end
end

function love.quit()
	saveConfig()
	saveHighscores()
	saveStats()
end
