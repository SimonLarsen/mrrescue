mainmenu = {}

local MENU_STRINGS = {
	"START GAME", "HOW TO PLAY", "HIGHSCORES", "OPTIONS", "HISTORY", "EXIT"
}

lg = love.graphics

function mainmenu.enter()
	state = STATE_MAINMENU
	selection = 1
end

function mainmenu.update(dt)
	updateKeys()
end

function mainmenu.draw()
	lg.push()
	lg.scale(config.scale)

	lg.draw(img.splash, quad.screen, 0,0)
	lg.setFont(font.bold)
	for i=1,6 do
		if i == selection then
			lg.print(">", 144, 86+i*13)
		end
		lg.print(MENU_STRINGS[i], 152, 86+i*13)
	end

	lg.pop()
end

function mainmenu.keypressed(k, uni)
	if k == "down" then
		selection = wrap(selection + 1, 1,6)
		playSound("blip")
	elseif k == "up" then
		selection = wrap(selection - 1, 1,6)
		playSound("blip")
	elseif k == "return" or k == " " then
		if selection == 1 then
			levelselection.enter()
		elseif selection == 2 then
			howto.enter()
		elseif selection == 3 then
			highscore_list.enter()
		elseif selection == 4 then
			options.enter()
		elseif selection == 5 then
			history.enter()
		elseif selection == 6 then
			love.event.quit()
		end
		playSound("confirm")
	elseif k == "escape" then
		love.event.quit()
	end
end

function mainmenu.action(k)
	if k == "down" then
		selection = wrap(selection + 1, 1,6)
		playSound("blip")
	elseif k == "up" then
		selection = wrap(selection - 1, 1,6)
		playSound("blip")
	elseif k == "jump" then
		if selection == 1 then
			levelselection.enter()
		elseif selection == 2 then
			howto.enter()
		elseif selection == 3 then
			highscore_list.enter()
		elseif selection == 4 then
			options.enter()
		elseif selection == 5 then
			history.enter()
		elseif selection == 6 then
			love.event.quit()
		end
		playSound("confirm")
	end
end
