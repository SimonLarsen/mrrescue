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

local MAX_FRAMETIME = 1/20
local MIN_FRAMETIME = 1/60

local AXIS_COOLDOWN = 0.2
local xacc = 0
local yacc = 0
local xacccool = 0
local yacccool = 0

STATE_SPLASH, STATE_INGAME, STATE_MAINMENU, STATE_LEVELSELECTION, STATE_OPTIONS, STATE_KEYBOARD, STATE_JOYSTICK,
STATE_HOWTO, STATE_HIGHSCORE_LIST, STATE_HIGHSCORE_ENTRY, STATE_INGAME_MENU, STATE_HISTORY, STATE_SUMMARY = 0,1,2,3,4,5,6,7,8,9,10,11,12

gamestates = {[0]=splash, [1]=ingame, [2]=mainmenu, [3]=levelselection, [4]=options, [5]=keyboard,
[6]=joystick, [7]=howto, [8]=highscore_list, [9]=highscore_entry, [10]=ingame_menu, [11]=history, [12]=summary}

function love.load()
	loadConfig()
	loadHighscores()
	loadStats()

	love.graphics.setBackgroundColor(0,0,0)

	love.graphics.setDefaultFilter("nearest","nearest")
	loadResources()

	setMode()

	splash.enter()
end

function love.update(dt)
	if xacccool > 0 then
		xacccool = xacccool - dt
	end
	if yacccool > 0 then
		yacccool = yacccool - dt
	end
	gamestates[state].update(dt)
end

function love.draw()
	-- Draw border and enable scissoring for fullscreen
	lg.push()
	setZoom()
	gamestates[state].draw()
	lg.pop()

	lg.setScissor()
	if state == STATE_INGAME and map.type == MT_NORMAL then
		updateLightmap()
	end
end

function setZoom()
	if config.fullscreen == 1 then
		local sw = love.graphics.getWidth()/WIDTH/config.scale
		local sh = love.graphics.getHeight()/HEIGHT/config.scale
		lg.scale(sw,sh)
	elseif config.fullscreen == 2 then
		local sw = love.graphics.getWidth()/WIDTH/config.scale
		local sh = love.graphics.getHeight()/HEIGHT/config.scale
		local tx = (love.graphics.getWidth() - WIDTH*config.scale*sh)/2
		lg.translate(tx, 0)
		lg.scale(sh, sh)
		lg.setScissor(tx, 0, WIDTH*config.scale*sh, love.graphics.getHeight())
	elseif config.fullscreen == 3 then
		lg.translate(fs_translatex,fs_translatey)
		lg.setScissor(fs_translatex, fs_translatey, WIDTH*config.scale, HEIGHT*config.scale)
	end
end

function love.keypressed(k, uni)
	gamestates[state].keypressed(k, uni)
end

function love.textinput(text)
	if gamestates[state].textinput then
		gamestates[state].textinput(text)
	end
end

function love.joystickpressed(joy, k)
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
	local joystick = love.joystick.getJoysticks()[1]
	if joystick == nil then return end

	local axis1, axis2 = joystick:getAxes()
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

		-- Check sudden movements in axes
		-- (for ladders and menus)
		xacc = xacc*0.50 + axis1*0.50
		yacc = yacc*0.50 + axis2*0.50

		if math.abs(axis1) < 0.1 then
			xacccool = 0
		end
		if math.abs(axis2) < 0.1 then
			yacccool = 0
		end

		if xacccool <= 0 then
			if axis1 < -0.90 then
				gamestates[state].action("left")
				xacccool = AXIS_COOLDOWN
			elseif axis1 > 0.90 then
				gamestates[state].action("right")
				xacccool = AXIS_COOLDOWN
			end
		end

		if yacccool <= 0 then
			if axis2 < -0.90 then
				gamestates[state].action("up")
				yacccool = AXIS_COOLDOWN
			elseif axis2 > 0.90 then
				gamestates[state].action("down")
				yacccool = AXIS_COOLDOWN
			end
		end
	end

	-- Check joystick keys
	for action, key in pairs(config.joykeys) do
		if joystick:isDown(key) then
			keystate[action] = true
		end
	end
end

function love.run()
    math.randomseed(os.time())
    math.random() math.random()

    if love.load then love.load(arg) end
    local dt = 0
	local acc = 0

    -- Main loop time.
    while true do
		local frame_start = love.timer.getTime()
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

		love.timer.step()
		dt = love.timer.getDelta()
		dt = math.min(dt, MAX_FRAMETIME)
		acc = acc + dt

		while acc >= MIN_FRAMETIME do
			love.update(MIN_FRAMETIME)
			acc = acc - MIN_FRAMETIME
		end

		-- Update screen
		love.graphics.clear()
		love.draw()

		love.graphics.present()
		love.timer.sleep(0.001)
    end
end

function love.quit()
	saveConfig()
	saveHighscores()
	saveStats()
end

function love.releaseerrhand(msg)
    print("An error has occured, the game has been stopped.")

    if not love.graphics or not love.event or not love.graphics.isCreated() then
        return
    end

    love.graphics.setCanvas()
    love.graphics.setPixelEffect()

    -- Load.
    if love.audio then love.audio.stop() end
    love.graphics.reset()
    love.graphics.setBackgroundColor(89, 157, 220)
    local font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    love.graphics.setColor(255, 255, 255, 255)

    love.graphics.clear()

    local err = {}

    p = string.format("An error has occured that caused %s to stop.\nYou can notify %s about this%s.\n\nError: %s", love._release.title or "this game", love._release.author or "the author", love._release.url and " at " .. love._release.url or "", msg)

    local function draw()
        love.graphics.clear()
        love.graphics.printf(p, 70, 70, love.graphics.getWidth() - 70)
        love.graphics.present()
    end

    draw()

    local e, a, b, c
    while true do
        e, a, b, c = love.event.wait()

        if e == "quit" then
            return
        end
        if e == "keypressed" and a == "escape" then
            return
        end

        draw()

    end
end
