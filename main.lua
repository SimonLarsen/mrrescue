require("resources")
require("util")
require("AnAL")
require("map")
require("player")
require("entity")
require("human")
require("enemy")
require("door")
require("item")
require("fire")
require("particles")

WIDTH = 256
HEIGHT = 200
MAPW = 41*16
MAPH = 16*16
translate_x, translate_y = 0,0
show_debug = false

local SCALE = 3
local MIN_FRAMERATE = 1/15
local MAX_FRAMERATE = 1/200

local lg = love.graphics

local STATE_INGAME, STATE_NEXTLEVEL_OUT, STATE_NEXTLEVEL_IN = 0,1,2

function love.load()
	lg.setBackgroundColor(82,117,176)
	lg.setMode(WIDTH*SCALE, HEIGHT*SCALE, false, true)
	lg.setDefaultImageFilter("nearest","nearest")

	lg.setFont(lg.newFont(16))

	loadResources()

	max_casualties = 3
	casualties = 0
	saved = 0

	state = STATE_NEXTLEVEL_IN
	transition_time = 0

	map = Map.create()
	player = Player.create(map:getStart())
end

function nextLevel()
	casualties = casualties + #map.humans
	map = Map.create()
	player.x, player.y = map.startx, map.starty
end

function love.update(dt)
	-- Cap framerate
	if dt > MIN_FRAMERATE then dt = MIN_FRAMERATE end
	if dt < MAX_FRAMERATE then
		love.timer.sleep(MAX_FRAMERATE - dt)
		dt = MAX_FRAMERATE
	end

	if love.keyboard.isDown("l") then
		dt = dt/4
	end

	-- INGAME STATE
	if state == STATE_INGAME then

		-- Update entities
		player:update(dt)

		-- Calculate translation offest
		translate_x = cap(player.x-WIDTH/2, 0, MAPW-WIDTH)
		translate_y = cap(player.y-11-HEIGHT/2, 0, MAPH-HEIGHT+30)

		map:setDrawRange(translate_x, translate_y, WIDTH, HEIGHT)
		map:update(dt)

		-- Set next level transition state if player has climbed out of the screen
		if player.y < 0 then
			state = STATE_NEXTLEVEL_OUT
			transition_time = 0
		end
	-- Transition TO or FROM next level
	elseif state == STATE_NEXTLEVEL_OUT or state == STATE_NEXTLEVEL_IN then
		transition_time = transition_time + dt*15

		-- Calculate translation offest
		translate_x = cap(player.x-WIDTH/2, 0, MAPW-WIDTH)
		translate_y = cap(player.y-11-HEIGHT/2, 0, MAPH-HEIGHT+30)

		map:setDrawRange(translate_x, translate_y, WIDTH, HEIGHT)
		map:update(dt)

		if transition_time > 20 then
			if state == STATE_NEXTLEVEL_OUT then
				nextLevel()
				state = STATE_NEXTLEVEL_IN
				transition_time = 0
			else -- STATE_NEXTLEVEL_IN
				state = STATE_INGAME
				transition_time = 0
			end
		end
	end
end

function love.draw()
	-- Scale screen
	lg.push()
	lg.scale(SCALE,SCALE)
	-- Translate to center player
	lg.push()
	lg.translate(-math.floor(translate_x), -math.floor(translate_y))

	-- Draw back
	map:drawBack()
	-- Draw player
	player:draw()
	-- Draw front
	map:drawFront()

	-- Update lightmap
	lg.pop()
	lg.pop()	
	lg.push()
	lg.translate(-math.floor(translate_x), -math.floor(translate_y))
	updateLightmap()
	lg.pop()

	-- Draw canvas with lighting
	lg.push()
	lg.scale(SCALE,SCALE)
	lg.setBlendMode("multiplicative")
	lg.draw(canvas, 0,0)
	lg.setBlendMode("alpha")

	-- Draw red screen if hit
	if player.heat > 0 then
		lg.setColor(255,255,255,cap(player.heat*255, 16, 255))
		lg.drawq(img.red_screen, quad.red_screen, 0,0)
		lg.setColor(255,255,255,255)
	end

	-- Draw transition if eligible
	if state == STATE_NEXTLEVEL_OUT then
		local frame = math.floor(transition_time)

		for ix = 0,7 do
			for iy = 0,5 do
				lg.drawq(img.circles, quad.circles[math.max(0,math.min(frame-13+ix+iy,6))], ix*32, iy*32)
			end
		end
	end
	if state == STATE_NEXTLEVEL_IN then
		local frame = math.floor(transition_time)

		for ix = 0,7 do
			for iy = 0,5 do
				lg.drawq(img.circles, quad.circles[6-math.max(0,math.min(frame-13+ix+iy,6))], ix*32, iy*32)
			end
		end
	end

	-- Draw hud
	drawHUD()

	-- Draw debug information
	lg.pop()
	if show_debug == true then
		drawDebug()
	end
end

function drawHUD()
	lg.draw(img.hud, 0, HEIGHT-32)

	-- Draw water tank bar
	local water_ratio = player.water / player.water_capacity
	quad.water_bar:setViewport(0, 0, math.floor(water_ratio*55+0.5), 11)
	if player.overloaded == false then
		if player.hasReserve == true then
			lg.drawq(img.reserve_bar, quad.water_bar, 10, HEIGHT-22)
		else
			lg.drawq(img.water_bar, quad.water_bar, 10, HEIGHT-22)
		end
	else
		lg.drawq(img.overloaded_bar, quad.water_bar, 10, HEIGHT-22)
	end

	-- Draw temperature bar
	local temp_length = math.floor((player.temperature/player.max_temperature)*81+0.5)
	quad.temperature_bar:setViewport(0,0, temp_length, 6)
	lg.drawq(img.temperature_bar, quad.temperature_bar, 90, HEIGHT-25)
	lg.drawq(img.temperature_bar, quad.temperature_bar_end, 90+temp_length, HEIGHT-25)

	-- Draw casualty count
	for i=1,max_casualties do
		if i<= casualties then
			lg.drawq(img.hud_people, quad.hud_people_red, 189+(i-1)*5, HEIGHT-25)
		else
			lg.drawq(img.hud_people, quad.hud_people_green, 189+(i-1)*5, HEIGHT-25)
		end
	end

	lg.draw(img.hud2, 0, HEIGHT-32)

	-- Draw item slots
	for i=1,3 do
		if i <= player.num_regens then
			lg.drawq(img.item_slots, quad.item_slot_regen, 93+(i-1)*6, HEIGHT-14)
		end
		if i <= player.num_tanks then
			lg.drawq(img.item_slots, quad.item_slot_tank, 115+(i-1)*6, HEIGHT-14)
		end
		if i <= player.num_suits then
			lg.drawq(img.item_slots, quad.item_slot_suit, 137+(i-1)*6, HEIGHT-14)
		end
	end

	-- Draw panic/burning human icons
	drawIcons()
end

function drawIcons()
	for i,v in ipairs(map.humans) do
		if (v.state == HS_BURN or v.state == HS_PANIC) and
		(v.x < translate_x or v.x > translate_x+WIDTH or v.y < translate_y or v.y > translate_y+174) then
			local deltax = v.x - (translate_x+WIDTH/2)
			local deltay = v.y - 12 - (translate_y+84)

			local xt,yt
			if deltax > 0 then xt = 114/deltax
			else xt = -114/deltax end
			if deltay > 0 then yt = 72/deltay
			else yt = -72/deltay end

			local t
			if xt > yt then t = yt
			else t = xt end
			
			if v.state == HS_BURN then
				lg.drawq(img.warning_icons, quad.warning_icons[1], WIDTH/2+t*deltax, 84+t*deltay, 0,1,1,11,10)
			else
				lg.drawq(img.warning_icons, quad.warning_icons[2], WIDTH/2+t*deltax, 84+t*deltay, 0,1,1,11,10)
			end
		end
	end
end

function updateLightmap()
	canvas:clear(0,0,0,255)
	lg.setCanvas(canvas)
	lg.setBlendMode("additive")

	lg.draw(img.light_player, player.flx-128, player.fly-138)
	map:drawFireLight()
	for i,v in ipairs(map.enemies) do
		v:drawLight()
	end
	
	-- Light up outside building
	lg.rectangle("fill", 0,0, 32, MAPH)
	lg.rectangle("fill", MAPW-32, 0, 32, MAPH)
	lg.setBlendMode("alpha")
	lg.setCanvas()
end

function drawDebug()
	for i,v in ipairs({{0,0,0,255},{255,255,255,255}}) do
		lg.setColor(v)
		lg.print("x: "..player.flx.."   y: "..player.fly,10+i,10+i)
		lg.print("xspeed: "..math.floor(player.xspeed).."   yspeed: "..math.floor(player.yspeed),10+i,30+i)
		lg.print("streamLength: "..math.floor(player.streamLength).."   streamCollided: ".. (player.streamCollided and "true" or "false"),10+i,50+i)
		lg.print("enemies: "..#map.enemies.."  humans: "..#map.humans,10+i,70+i)
		lg.print("objects: "..#map.objects.."  particles: "..#map.particles,10+i,90+i)
	end
end

function love.keypressed(k, uni)
	if k == "escape" then
		love.event.quit()
	elseif k == "f1" then
		show_debug = not show_debug
	elseif k == "i" then
		map:addFire(math.floor(player.x/16), math.floor((player.y-8)/16))
	else
		player:keypressed(k)
	end
end

function love.joystickpressed(joy, k)
	player:joystickpressed(joy,k)
end
