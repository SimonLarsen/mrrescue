ingame_menu = {}

local lg = love.graphics

function ingame_menu.enter()
	playSound("blip")
	state = STATE_INGAME_MENU
	ingame_menu.selection = 1
end

function ingame_menu.update(dt)
	updateKeys()
end

function ingame_menu.draw()
	lg.push()
	ingame.draw()
	lg.pop()

	lg.scale(config.scale)
	lg.setColor(0,0,0,238)
	lg.rectangle("fill", 0, 0, WIDTH, HEIGHT)

	lg.setColor(255,255,255,255)
	lg.printf("PAUSED", 0, 46, WIDTH, "center")
	lg.print("RESUME", 103, 92)
	lg.print("QUIT", 103, 106)
	lg.print(">", 92, 77+ingame_menu.selection*14)
end

function ingame_menu.keypressed(k, uni)
	if k == "down" then
		ingame_menu.selection = wrap(ingame_menu.selection+1, 1,2)
		playSound("blip")
	elseif k == "up" then
		ingame_menu.selection = wrap(ingame_menu.selection-1, 1,2)
		playSound("blip")
	elseif k == " " or k == "return" then
		if ingame_menu.selection == 1 then
			state = STATE_INGAME
			playSound("confirm")
		elseif ingame_menu.selection == 2 then
			mainmenu.enter()
			playSound("confirm")
			playMusic("opening")
		end
	elseif k == "escape" then
		state = STATE_INGAME
		playSound("blip")
	end
end

function ingame_menu.action(k)
	if k == "down" then
		ingame_menu.selection = wrap(ingame_menu.selection+1, 1,2)
		playSound("blip")
	elseif k == "up" then
		ingame_menu.selection = wrap(ingame_menu.selection-1, 1,2)
		playSound("blip")
	elseif k == "pause" or k == "jump" then
		if ingame_menu.selection == 1 then
			state = STATE_INGAME
			playSound("confirm")
		elseif ingame_menu.selection == 2 then
			mainmenu.enter()
			playSound("confirm")
			playMusic("opening")
		end
	elseif k == "action" then
		state = STATE_INGAME
		playSound("blip")
	end
end
