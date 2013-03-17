ingame = {}

local lg = love.graphics
INGAME_ACTIVE, INGAME_FADE_IN, INGAME_NEXTLEVEL_OUT, INGAME_FALL_OUT, INGAME_PRESCREEN, INGAME_GAMEOVER_OUT, INGAME_GAMEOVER, INGAME_WON = 0,1,2,3,4,5,6,7

function ingame.enter()
	state = STATE_INGAME
	translate_x, translate_y = 0,0
	playMusic(table.random({"rockerronni","bundesliga","scooterfest"}))

	ingame.newGame()
end

function ingame.newGame()
	ingame_state = INGAME_PRESCREEN
	max_casualties = 6-level
	ingame.shake = 0

	casualties = 0
	score = 0
	saved = 0
	section = 1
	last_missed = 0

	transition_time = 0
	warning_frame = 0

	map = Map.create(section, level)
	player = Player.create(map:getStart())

	setPrescreenMessage()
end

function ingame.nextLevel()
	last_missed = #map.humans
	casualties = casualties + last_missed

	if casualties >= max_casualties then
		ingame_state = INGAME_GAMEOVER
	else
		ingame_state = INGAME_PRESCREEN
		score = score + 1000
		section = section + 1
		map = Map.create(section, level)
		player:warp(map:getStart())
	end
end

function ingame.update(dt)
	if love.keyboard.isDown("e") then
		dt = dt/4
	end

	-- INGAME STATE
	if ingame_state == INGAME_ACTIVE then
		updateKeys()

		-- Update entities
		player:update(dt)

		-- Calculate translation offest
		translate_x = cap(player.x-WIDTH/2, 0, MAPW-WIDTH)
		translate_y = cap(player.y-11-HEIGHT/2, 0, MAPH-HEIGHT+30)
		if ingame.shake > 0 then
			ingame.shake = ingame.shake - dt
		end

		map:setDrawRange(translate_x, translate_y, WIDTH, HEIGHT)
		map:update(dt)

		-- Set next level transition state if player has climbed out of the screen
		if player.y < 0 then
			ingame_state = INGAME_NEXTLEVEL_OUT
			transition_time = 0
		-- Set out of screen transition if player has fallen out of screen
		elseif player.y > MAPH+32 then
			ingame_state = INGAME_FALL_OUT
			transition_time = 0
		end

		-- Update warning icon frame
		warning_frame = (warning_frame + dt*2) % 2

	-- Transition TO or FROM next level
	elseif ingame_state == INGAME_NEXTLEVEL_OUT or ingame_state == INGAME_FALL_OUT
	or ingame_state == INGAME_FADE_IN or ingame_state == INGAME_GAMEOVER_OUT then
		transition_time = transition_time + dt*15

		-- Calculate translation offest
		translate_x = cap(player.x-WIDTH/2, 0, MAPW-WIDTH)
		translate_y = cap(player.y-11-HEIGHT/2, 0, MAPH-HEIGHT+30)

		map:setDrawRange(translate_x, translate_y, WIDTH, HEIGHT)
		map:update(dt)

		if transition_time > 20 then
			if ingame_state == INGAME_NEXTLEVEL_OUT then
				ingame.nextLevel()
				setPrescreenMessage()
			elseif ingame_state == INGAME_FALL_OUT then
				player:warp(map:getStart())
				ingame_state = INGAME_FADE_IN
			elseif ingame_state == INGAME_FADE_IN then
				ingame_state = INGAME_ACTIVE
			elseif ingame_state == INGAME_GAMEOVER_OUT then
				setPrescreenMessage()
				ingame_state = INGAME_GAMEOVER
			end
			transition_time = 0
		end
	elseif ingame_state == INGAME_PRESCREEN or ingame_state == INGAME_GAMEOVER then
		transition_time = transition_time + dt*3
	elseif ingame_state == INGAME_WON then
		if translate_y > -HEIGHT then
			translate_y = translate_y - dt*20
		end
		map:setDrawRange(translate_x, translate_y, WIDTH, HEIGHT)
		map:update(dt)
	end
end

function ingame.draw()
	-- Scale screen
	lg.push()
	lg.scale(config.scale)

	if ingame_state == INGAME_ACTIVE or ingame_state == INGAME_FADE_IN
	or ingame_state == INGAME_NEXTLEVEL_OUT or ingame_state == INGAME_FALL_OUT
	or ingame_state == INGAME_GAMEOVER_OUT or ingame_state == INGAME_WON then
		-- Translate to center player
		lg.push()
		if ingame.shake > 0 then
			lg.translate(-math.floor(translate_x+math.random()*4-2), -math.floor(translate_y+math.random()*2.5))
		else
			lg.translate(-math.floor(translate_x), -math.floor(translate_y))
		end

		-- Draw back
		map:drawBack()
		-- Draw player
		player:draw()
		-- Draw front
		map:drawFront()

		if player.state == PS_DEAD then
			player:draw()
		end

		-- Update lightmap
		if map.type == MT_NORMAL then
			lg.pop()
			lg.pop()	
			lg.push()
			lg.translate(-math.floor(translate_x), -math.floor(translate_y))
			updateLightmap()
			lg.pop()

			-- Draw canvas with lighting
			lg.push()
			lg.scale(config.scale)
			lg.setBlendMode("multiplicative")
			lg.draw(canvas, 0,0)
			lg.setBlendMode("alpha")
		else
			lg.pop()
			lg.pop()
			lg.push()
			lg.scale(config.scale)
		end

		-- Draw red screen if hit
		if player.heat > 0 then
			lg.setColor(255,255,255,cap(player.heat*255, 16, 255))
			lg.drawq(img.red_screen, quad.red_screen, 0,0)
			lg.setColor(255,255,255,255)
		end

		-- Draw hud
		drawHUD()

		-- Draw transition if eligible
		if ingame_state == INGAME_NEXTLEVEL_OUT or ingame_state == INGAME_FALL_OUT or ingame_state == INGAME_GAMEOVER_OUT then
			local frame = math.floor(transition_time)

			for ix = 0,7 do
				for iy = 0,6 do
					lg.drawq(img.circles, quad.circles[math.max(0,math.min(frame-13+ix+iy,6))], ix*32, iy*32)
				end
			end
		end
		if ingame_state == INGAME_FADE_IN then
			local frame = math.floor(transition_time)

			for ix = 0,7 do
				for iy = 0,6 do
					lg.drawq(img.circles, quad.circles[6-math.max(0,math.min(frame-13+ix+iy,6))], ix*32, iy*32)
				end
			end
		end
		if ingame_state == INGAME_WON then
			if translate_y < 0 then
				printWonMessage()
			end
		end

	elseif ingame_state == INGAME_PRESCREEN then
		drawPrescreen()
	
	elseif ingame_state == INGAME_GAMEOVER then
		drawGameover()
	end

	lg.pop()
end
 
function printWonMessage()
	local alpha = cap((-translate_y)/100, 0, 1)
	lg.setColor(0,0,0,alpha*255)
	lg.rectangle("fill", 0, 40, WIDTH,  #WON_MESSAGES[level]*10+8)
	lg.setColor(255,255,255,alpha*255)
	for i,v in ipairs(WON_MESSAGES[level]) do
		lg.printf(v, 0, 48+(i-1)*10, WIDTH, "center")
	end
	lg.setColor(255,255,255,255)
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
	lg.drawq(img.temperature_bar, quad.temperature_bar, 75, HEIGHT-25)
	lg.drawq(img.temperature_bar, quad.temperature_bar_end, 75+temp_length, HEIGHT-25)

	-- Draw casualty count
	for i=1,max_casualties do
		if i<= casualties then
			lg.drawq(img.hud_people, quad.hud_people_red, 168+(i-1)*5, HEIGHT-25)
		else
			lg.drawq(img.hud_people, quad.hud_people_green, 168+(i-1)*5, HEIGHT-25)
		end
	end

	lg.draw(img.hud2, 0, HEIGHT-32)

	-- Draw item slots
	for i=1,3 do
		if i <= player.num_regens then
			lg.drawq(img.item_slots, quad.item_slot_regen, 78+(i-1)*6, HEIGHT-14)
		end
		if i <= player.num_tanks then
			lg.drawq(img.item_slots, quad.item_slot_tank, 100+(i-1)*6, HEIGHT-14)
		end
		if i <= player.num_suits then
			lg.drawq(img.item_slots, quad.item_slot_suit, 122+(i-1)*6, HEIGHT-14)
		end
	end

	-- Draw score
	lg.setFont(font.bold)
	lg.setColor(16,12,9)
	lg.print("SCORE: "..score,150,187)
	lg.setColor(246,247,221)
	lg.print("SCORE: "..score,150,186)
	lg.setColor(255,255,255)

	-- Draw boss health bar
	if map.type == MT_BOSS and ingame_state ~= INGAME_WON then
		lg.drawq(img.boss_health, quad.boss_health, 0, 11)
		local boss_length = math.floor((map.boss.health/map.boss.MAX_HEALTH)*178+0.5)
		lg.drawq(img.boss_health, quad.boss_bar, 64,22, 0, boss_length, 1)
		lg.drawq(img.boss_health, quad.boss_bar_end, 64+boss_length,22, 0)

		local bossframe = 0
		if map.boss.angry == true then bossframe = bossframe + 2 end
		if map.boss.hit == true or map.boss.state == BS_DEAD then bossframe = bossframe + 1 end
		lg.drawq(map.boss:getPortraitImage(), quad.boss_portrait[bossframe], 15,15)
		map.boss.hit = false
	end

	-- Draw panic/burning human icons
	drawIcons()
end

function drawPrescreen()
	local floor = section*3-2
	lg.setFont(font.bold)
	if map.type == MT_NORMAL then
		lg.printf("FLOOR ".. floor .. "-" .. floor+2, 0, 40, WIDTH, "center")
	else
		lg.printf("ROOF", 0, 40, WIDTH, "center")
	end

	local fr = math.floor(transition_time) % 2
	lg.drawq(img.captain_dialog, quad.captain_dialog[fr], 28, 72)
	drawPrescreenMessage()

	lg.printf("PRESS ANY KEY TO CONTINUE", 0, 150, WIDTH, "center")
end

function drawGameover()
	local fr = math.floor(transition_time) % 2
	lg.drawq(img.captain_dialog, quad.captain_dialog[fr], 28, 72)

	if casualties >= max_casualties then
		drawPrescreenMessage()
	elseif player.state == PS_DEAD then
		drawPrescreenMessage()
	end
end

function drawPrescreenMessage()
	for i=1,#prescreen_message do
		lg.print(prescreen_message[i], 73, 69+i*11)
	end
end

function setPrescreenMessage()
	if casualties >= max_casualties then
		prescreen_message = {"TOO MANY CASUALTIES!"}

	elseif player.state == PS_DEAD then
		prescreen_message = {"OVERHEATED!"}
	else
		if section == 1 then
			prescreen_message = table.random(GOODLUCK_MESSAGES)
		elseif map.type == MT_BOSS then
			prescreen_message = BOSS_MESSAGE
		elseif last_missed > 0 then
			if last_missed == 1 then
				prescreen_message = {"HEY THERE, BUDDY!","YOU MISSED 1 PERSON.","TRY A LITTLE HARDER."}
			else
				prescreen_message = {"HEY THERE, BUDDY!","YOU LET "..last_missed.." PEOPLE","BURN TO DEATH.","TRY A LITTLE HARDER."}
			end
		else
			prescreen_message = table.random(NO_CASUALTIES_MESSAGES)
		end
	end
end

--- Draws warning icons for panicing/burning/dead enemies
function drawIcons()
	-- Draw for panicing/burning humans
	for i,v in ipairs(map.humans) do
		if (v.state == HS_BURN or v.state == HS_PANIC) and
		(v.x < translate_x or v.x > translate_x+WIDTH or v.y < translate_y or v.y > translate_y+174) then
			if v.state == HS_BURN then
				drawIcon(v.x, v.y-12, 0)
			else
				drawIcon(v.x, v.y-12, 2)
			end
		end
	end
	-- Draw for ashes particles (dead humans)
	for i,v in ipairs(map.particles) do
		if v.isAshes == true and
		(v.x < translate_x or v.x > translate_x+WIDTH or v.y < translate_y or v.y > translate_y+174) then
			drawIcon(v.x, v.y-12, 4)
		end
	end
end

--- Draws a warning icon for an entity.
--  Does not check if entity is actually outside screen.
--  @param x X position of entity
--  @param y Y position of entity
--  @param frame_offset Offset into warning icon quad array
function drawIcon(x,y,frame_offset)
	local frame = cap(frame_offset + math.floor(warning_frame), 0, 4)
	local deltax = x - (translate_x+WIDTH/2)
	local deltay = y - (translate_y+84)

	local xt,yt
	if deltax > 0 then xt = 114/deltax
	else xt = -114/deltax end
	if deltay > 0 then yt = 72/deltay
	else yt = -72/deltay end

	local t
	if xt > yt then t = yt
	else t = xt end
	
	lg.drawq(img.warning_icons, quad.warning_icons[frame], WIDTH/2+t*deltax, 84+t*deltay, 0,1,1,11,10)
end

--- Updates the light map canvas
--  Assumes the view matrix is translated but not scaled
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

function ingame.action(a)
	player:action(a)
end

function ingame.keypressed(k, uni)
	if ingame_state == INGAME_ACTIVE then
		player:keypressed(k)
	elseif ingame_state == INGAME_PRESCREEN then
		ingame_state = INGAME_FADE_IN
		transition_time = 0
	elseif ingame_state == INGAME_GAMEOVER then
		levelselection.enter()
	elseif ingame_state == INGAME_WON then
		levelselection.enter()
	end
end

function ingame.joystickpressed(joy, k)
	if ingame_state == INGAME_ACTIVE then
		player:joystickpressed(joy, k)
	elseif ingame_state == INGAME_PRESCREEN then
		ingame_state = INGAME_FADE_IN
		transition_time = 0
	elseif ingame_state == INGAME_GAMEOVER then
		levelselection.enter()
	elseif ingame_state == INGAME_WON then
		levelselection.enter()
	end
end
