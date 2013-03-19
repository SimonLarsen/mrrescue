highscore_list = {}

local lg = love.graphics

function highscore_list.enter()
	state = STATE_HIGHSCORE_LIST
	playMusic("happyfeerings")
	highscore_list.level = 1
end

function highscore_list.update(dt)
	updateKeys()
end

function highscore_list.draw()
	lg.push()
	lg.scale(config.scale)

	drawBox(12, 20, 233, 172)
	lg.drawq(img.highscore_panes, quad.highscore_pane[highscore_list.level], 0, 10)

	lg.pop()
end

function highscore_list.keypressed(k, uni)
	if k == "right" then
		highscore_list.level = cap(highscore_list.level + 1, 1, 3)
		playSound("blip")
	elseif k == "left" then
		highscore_list.level = cap(highscore_list.level - 1, 1, 3)
		playSound("blip")
	elseif k == "return" or k == "escape" then
		playSound("confirm")
		playMusic("opening")
		mainmenu.enter()
	end
end

function highscore_list.joystickpressed(joy, k)
	if k == 3 or k == 4 then
		playSound("confirm")
		playMusic("opening")
		mainmenu.enter()
	end
end

function highscore_list.action(k)
	if k == "right" then
		highscore_list.level = cap(highscore_list.level + 1, 1, 3)
		playSound("blip")
	elseif k == "left" then
		highscore_list.level = cap(highscore_list.level - 1, 1, 3)
		playSound("blip")
	end
end
