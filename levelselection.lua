levelselection = {}

local lg = love.graphics

function levelselection.enter()
	state = STATE_LEVELSELECTION
	level = 1
	playMusic("menujazz")
end

function levelselection.update(dt)
	
end

function levelselection.draw()
	lg.push()
	lg.scale(config.scale)

	lg.print("PLEASE SELECT", 129, 11)
	lg.print("A LEVEL", 151, 22)
	lg.drawq(img.level_buildings, quad.level_buildings, 116, 34)
	drawBox(6,82,126,69)
	drawBox(6,44,126,38)

	if level == 1 then
		lg.drawq(img.level_buildings, quad.building_outline1, 138,121)
	elseif level == 2 then
		lg.drawq(img.level_buildings, quad.building_outline2, 192,108)
	else
		lg.drawq(img.level_buildings, quad.building_outline3, 156,43)
	end

	lg.printf(BUILDING_NAMES[level][1], 16, 54, 107, "center")
	lg.printf(BUILDING_NAMES[level][2], 16, 66, 107, "center")
	lg.print(DIFFICULTY_NAMES[level], 16, 92)
	lg.print("FLOORS: "..level*30, 16, 106)
	lg.print("MISSES: "..string.rep("@",2+level), 16, 120)
	lg.print("BEST: "..level*1234, 16, 134)

	lg.pop()
end

function levelselection.keypressed(k, uni)
	if k == "right" or k == "down" then
		level = level + 1
		if level > 3 then level = 1 end
		playSound("blip")
	elseif k == "left" or k == "up" then
		level = level - 1
		if level < 1 then level = 3 end
		playSound("blip")
	elseif k == "return" or k == " " then
		ingame.enter(level)
		playSound("confirm")
	end
end

function levelselection.joystickpressed(joy, k)
	
end
