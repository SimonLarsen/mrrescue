history = {}

local lg = love.graphics

function history.enter()
	state = STATE_HISTORY
	playMusic("happyfeerings")
	history.selection = 1
end

function history.update(dt)
	updateKeys()
end

function history.draw()
	lg.push()
	lg.scale(config.scale)

	lg.printf("STATS", 0, 32, WIDTH, "center")
	lg.draw(img.stats_screen, quad.screen, 0,16)
	lg.draw(img.stats_screen, quad.stats_pane[history.selection], 58, 48)

	for i=1,2 do
		local index = i + (history.selection-1)*2
		lg.printf(stats_names[index], 78, 16+i*56, 112, "left")
		if stats_units[index] then
			lg.print(math.floor(stats[index]) .. stats_units[index], 78, 40+i*56)
		else
			lg.print(math.floor(stats[index]), 78, 40+i*56)
		end

		if stats[index] > stats_interval[index][3] then
			lg.draw(img.awards, quad.award_gold[index], 46, 10+i*56)
		elseif stats[index] > stats_interval[index][2] then
			lg.draw(img.awards, quad.award_silver[index], 46, 10+i*56)
		elseif stats[index] > stats_interval[index][1] then
			lg.draw(img.awards, quad.award_bronze[index], 46, 10+i*56)
		else
			lg.draw(img.awards, quad.award_none[index], 46, 10+i*56)
		end
	end

	lg.pop()
end

function history.keypressed(k, uni)
	if k == "right" then
		history.selection = wrap(history.selection+1, 1, 3)
		playSound("blip")
	elseif k == "left" then
		history.selection = wrap(history.selection-1, 1, 3)
		playSound("blip")
	elseif k == "escape" then
		playSound("confirm")
		playMusic("opening")
		mainmenu.enter()
	end
end

function history.action(k)
	if k == "right" then
		history.selection = wrap(history.selection+1, 1, 3)
		playSound("blip")
	elseif k == "left" then
		history.selection = wrap(history.selection-1, 1, 3)
		playSound("blip")
	elseif k == "action" then
		playSound("confirm")
		playMusic("opening")
		mainmenu.enter()
	end
end
