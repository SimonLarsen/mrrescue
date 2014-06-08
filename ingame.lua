ingame = {}

local lg = love.graphics
INGAME_ACTIVE, INGAME_FADE_IN, INGAME_NEXTLEVEL_OUT, INGAME_FALL_OUT, INGAME_PRESCREEN,
INGAME_GAMEOVER_OUT, INGAME_GAMEOVER, INGAME_WON, INGAME_COUNTDOWN, INGAME_COUNTDOWN_IN = 0,1,2,3,4,5,6,7,8,9

COMBO_TIME = 4

function ingame.enter()
	state = STATE_INGAME
	translate_x, translate_y = 0,0
	
	stopMusic()
	ingame.newGame()
end

function ingame.newGame()
	ingame_state = INGAME_COUNTDOWN_IN
	max_casualties = 6-level
	ingame.shake = 0

	casualties = 0
	score = 0
	saved = 0
	section = 1
	last_missed = 0
	last_rescue = 0
	combo = 0
	max_combo = 0
	time = 0

	transition_time = 0
	warning_frame = 0

	map = Map.create(section, level)
	local startx, starty = map:getStart()
	player = Player.create(startx,starty,level)
end

function ingame.nextLevel()
	last_missed = #map.humans
	casualties = casualties + last_missed
	stats[6] = stats[6] + 3

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

	updateKeys()

	-- INGAME STATE
	if ingame_state == INGAME_ACTIVE then
		time = time + dt

		-- Check combo counter
		last_rescue = last_rescue + dt
		if last_rescue > COMBO_TIME then
			max_combo = math.max(max_combo, combo)
			combo = 0
		end

		-- Update map entities
		map:update(dt)

		-- Update entities
		player:update(dt)

		-- Calculate translation offest
		translate_x = cap(player.x-WIDTH/2, 0, MAPW-WIDTH)
		translate_y = cap(player.y-11-HEIGHT/2, 0, MAPH-HEIGHT+30)
		if ingame.shake > 0 then
			ingame.shake = ingame.shake - dt
		end
		map:setDrawRange(translate_x, translate_y, WIDTH, HEIGHT)

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

		-- Kill player if too many casualties
		if casualties >= max_casualties then
			player.temperature = player.max_temperature
		end

	-- Transition TO or FROM next level
	elseif ingame_state == INGAME_NEXTLEVEL_OUT or ingame_state == INGAME_FALL_OUT
	or ingame_state == INGAME_FADE_IN or ingame_state == INGAME_GAMEOVER_OUT
	or ingame_state == INGAME_COUNTDOWN_IN then
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
			elseif ingame_state == INGAME_COUNTDOWN_IN then
				ingame_state = INGAME_COUNTDOWN
				playSound("countdown")
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
	elseif ingame_state == INGAME_COUNTDOWN then
		-- Calculate translation offest
		translate_x = cap(player.x-WIDTH/2, 0, MAPW-WIDTH)
		translate_y = cap(player.y-11-HEIGHT/2, 0, MAPH-HEIGHT+30)

		map:setDrawRange(translate_x, translate_y, WIDTH, HEIGHT)
		map:update(dt)

		transition_time = transition_time + dt
		if transition_time >= 3.5 then
			ingame_state = INGAME_ACTIVE
			playMusic(table.random({"rockerronni","bundesliga","scooterfest"}))
		end
	end
end

function ingame.draw()
	-- Scale screen
	lg.push()
	lg.scale(config.scale)

	if ingame_state == INGAME_ACTIVE or ingame_state == INGAME_FADE_IN
	or ingame_state == INGAME_NEXTLEVEL_OUT or ingame_state == INGAME_FALL_OUT
	or ingame_state == INGAME_GAMEOVER_OUT or ingame_state == INGAME_WON
	or ingame_state == INGAME_COUNTDOWN_IN or ingame_state == INGAME_COUNTDOWN then
		lg.push()
		-- Translate to center player
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

		lg.pop()

		if map.type == MT_NORMAL then
			lg.setBlendMode("multiplicative")
			lg.draw(canvas, 0,0)
			lg.setBlendMode("alpha")
		end

		-- Draw red screen if hit
		if player.heat > 0 then
			lg.setColor(255,255,255,cap(player.heat*255, 16, 255))
			lg.draw(img.red_screen, quad.red_screen, 0,0)
			lg.setColor(255,255,255,255)
		end

		-- Draw hud
		drawHUD()

		-- Draw transition if eligible
		if ingame_state == INGAME_NEXTLEVEL_OUT or ingame_state == INGAME_FALL_OUT or ingame_state == INGAME_GAMEOVER_OUT then
			local frame = math.floor(transition_time)
			lg.pop()
			--lg.pop()
			lg.push()
			lg.scale(config.scale)

			for ix = 0,7 do
				for iy = 0,6 do
					lg.draw(img.circles, quad.circles[math.max(0,math.min(frame-13+ix+iy,6))], ix*32, iy*32)
				end
			end
		end
		if ingame_state == INGAME_FADE_IN or ingame_state == INGAME_COUNTDOWN_IN then
			local frame = math.floor(transition_time)

			for ix = 0,7 do
				for iy = 0,6 do
					lg.draw(img.circles, quad.circles[6-math.max(0,math.min(frame-13+ix+iy,6))], ix*32, iy*32)
				end
			end
		end
		if ingame_state == INGAME_WON then
			if translate_y < 0 then
				drawWonMessage()
			end
		end
		if ingame_state == INGAME_COUNTDOWN then
			local frame = math.floor(transition_time)
			lg.draw(img.countdown, quad.countdown[frame], 96, 87)
		end

	elseif ingame_state == INGAME_PRESCREEN then
		drawPrescreen()
	
	elseif ingame_state == INGAME_GAMEOVER then
		drawGameover()
	end

	lg.pop()
end
 
function drawWonMessage()
	local alpha = cap((-translate_y)/100, 0, 1)
	lg.setColor(0,0,0,alpha*255)
	lg.rectangle("fill", 0, 40, WIDTH, #WON_MESSAGES[level]*10+12)
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
			lg.draw(img.reserve_bar, quad.water_bar, 10, HEIGHT-22)
		else
			lg.draw(img.water_bar, quad.water_bar, 10, HEIGHT-22)
		end
	else
		lg.draw(img.overloaded_bar, quad.water_bar, 10, HEIGHT-22)
	end

	-- Draw temperature bar
	local temp_length = math.floor((player.temperature/player.max_temperature)*82+0.5)
	quad.temperature_bar:setViewport(0,0, temp_length, 6)
	lg.draw(img.temperature_bar, quad.temperature_bar, 75, HEIGHT-25)
	lg.draw(img.temperature_bar, quad.temperature_bar_end, 75+temp_length, HEIGHT-25)

	-- Draw casualty count
	for i=1,max_casualties do
		if i<= casualties then
			lg.draw(img.hud_people, quad.hud_people_red, 168+(i-1)*5, HEIGHT-25)
		else
			lg.draw(img.hud_people, quad.hud_people_green, 168+(i-1)*5, HEIGHT-25)
		end
	end

	-- Draw second HUD layer
	lg.draw(img.hud2, 0, HEIGHT-32)

	-- Blink temperature bar if needed
	if player:isDying() then
		local color = 0
		if warning_frame <= 1 then
			color = 30 + warning_frame * 225
		else
			color = 255 - (warning_frame % 1)*225
		end
		lg.setColor(255,color,color)
		lg.draw(img.temperature_bar_blink, 74, HEIGHT-26)
		lg.setColor(255,255,255)
	end

	-- Draw item slots
	for i=1,3 do
		if i <= player.num_regens then
			lg.draw(img.item_slots, quad.item_slot_regen, 78+(i-1)*6, HEIGHT-14)
		end
		if i <= player.num_tanks then
			lg.draw(img.item_slots, quad.item_slot_tank, 100+(i-1)*6, HEIGHT-14)
		end
		if i <= player.num_suits then
			lg.draw(img.item_slots, quad.item_slot_suit, 122+(i-1)*6, HEIGHT-14)
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
		lg.draw(img.boss_health, quad.boss_health, 0, 11)
		local boss_length = math.floor((map.boss.health/map.boss.MAX_HEALTH)*178+0.5)
		lg.draw(img.boss_health, quad.boss_bar, 64,22, 0, boss_length, 1)
		lg.draw(img.boss_health, quad.boss_bar_end, 64+boss_length,22, 0)

		local bossframe = 0
		if map.boss.angry == true then bossframe = bossframe + 2 end
		if map.boss.hit == true or map.boss.state == BS_DEAD then bossframe = bossframe + 1 end
		lg.draw(map.boss:getPortraitImage(), quad.boss_portrait[bossframe], 15,15)
	end

	-- Draw panic/burning human icons
	drawIcons()
end

function drawPrescreen()
	local floor = section*3-2
	lg.setFont(font.bold)
	if map.type == MT_NORMAL then
		lg.printf("FLOOR ".. floor .. "-" .. floor+2, 0, 40, WIDTH, "center")
		lg.draw(img.captain_dialog, quad.prescreen_music, 7, 183)
	else
		lg.printf("ROOF", 0, 40, WIDTH, "center")
	end

	local fr = math.floor(transition_time) % 2
	lg.draw(img.captain_dialog, quad.captain_dialog[fr], 28, 72)

	lg.printf(prescreen_message, 74, 80, 150, "left")

	lg.printf("PRESS RETURN TO CONTINUE", 0, 150, WIDTH, "center")
end

function drawGameover()
	local fr = math.floor(transition_time) % 2
	lg.draw(img.captain_dialog_sad, quad.captain_dialog[fr], 28, 72)

	if casualties >= max_casualties then
		lg.printf(prescreen_message, 74, 80, 140, "left")
	elseif player.state == PS_DEAD then
		lg.printf(prescreen_message, 74, 80, 140, "left")
	end
end

function setPrescreenMessage()
	if casualties >= max_casualties then
		prescreen_message = "TOO MANY CIVILIANS HAVE DIED!\n\nYOU ARE FIRED!"
	elseif player.state == PS_DEAD then
		prescreen_message = "YOUR SUIT OVERHEATED!\n\nGAME OVER"
	else
		if section == 1 then
			prescreen_message = table.random(GOODLUCK_MESSAGES)
		elseif map.type == MT_BOSS then
			prescreen_message = BOSS_MESSAGE[level]
			playMusic("roof")
		elseif last_missed > 0 then
			if last_missed == 1 then
				prescreen_message = "HEY THERE, BUDDY!\nYOU MISSED 1 PERSON.\nTRY A LITTLE HARDER."
			else
				prescreen_message = "HEY THERE, BUDDY!\nYOU LET "..last_missed.." PEOPLE BURN TO DEATH.\nTRY A LITTLE HARDER."
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
	
	lg.draw(img.warning_icons, quad.warning_icons[frame], WIDTH/2+t*deltax, 84+t*deltay, 0,1,1,11,10)
end

--- Updates the light map canvas
--  Assumes the view matrix is translated but not scaled
function updateLightmap()
	if ingame_state == INGAME_ACTIVE or ingame_state == INGAME_FADE_IN
	or ingame_state == INGAME_NEXTLEVEL_OUT or ingame_state == INGAME_FALL_OUT
	or ingame_state == INGAME_GAMEOVER_OUT or ingame_state == INGAME_WON
	or ingame_state == INGAME_COUNTDOWN_IN or ingame_state == INGAME_COUNTDOWN then
		lg.push()
		lg.translate(-math.floor(translate_x), -math.floor(translate_y))
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
		lg.pop()
	end
end

function ingame.keypressed(k,uni)
	if ingame_state == INGAME_ACTIVE then
		if k == "escape" then
			ingame_menu.enter()
		elseif k == "p" then
			map:addParticle(PopupText.create("megacombo"))
		else
			for a, key in pairs(config.keys) do
				if k == key then
					player:action(a)
				end
			end
		end
	elseif ingame_state == INGAME_PRESCREEN then
		if k == "return" or k == " " then
			ingame_state = INGAME_FADE_IN
			transition_time = 0
		elseif k == "left" then
			prevSong()
		elseif k == "right" then
			nextSong()
		end
	elseif ingame_state == INGAME_GAMEOVER then
		if k == "return" or k == " " then
			summary.enter()
		end
	elseif ingame_state == INGAME_WON and translate_y < 0 then
		if k == "return" or k == " " then
			summary.enter()
		end
	end
end

function ingame.action(k)
	if ingame_state == INGAME_ACTIVE then
		if k == "pause" then
			ingame_menu.enter()
		else
			player:action(k)
		end
	elseif ingame_state == INGAME_PRESCREEN then
		if k == "left" then
			prevSong()
		elseif k == "right" then
			nextSong()
		else
			ingame_state = INGAME_FADE_IN
			transition_time = 0
		end
	elseif ingame_state == INGAME_GAMEOVER then
		summary.enter()
	elseif ingame_state == INGAME_WON and translate_y < 0 then
		summary.enter()
	end
end
