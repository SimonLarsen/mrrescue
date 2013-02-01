mainmenu = {}

local MENU_STRINGS = {
	"START GAME", "HIGHSCORES", "OPTIONS", "HISTORY", "EXIT"
}

lg = love.graphics

function mainmenu.enter()
	state = STATE_MAINMENU
	selection = 1
end

function mainmenu.update(dt)

end

function mainmenu.draw()
	lg.push()
	lg.scale(SCALE)

	lg.drawq(img.splash, quad.splash, 0,0)
	lg.setFont(font.bold)
	for i=1,5 do
		if i == selection then
			lg.print(">", 144, 91+i*13)
		end
		lg.print(MENU_STRINGS[i], 152, 91+i*13)
	end

	lg.pop()
end

function mainmenu.keypressed(k, uni)
	if k == "down" then
		selection = selection + 1
		if selection > 5 then selection = 1 end
	elseif k == "up" then
		selection = selection - 1
		if selection < 1 then selection = 5 end
	elseif k == "return" or k == " " then
		if selection == 1 then
			levelselection.enter()
		elseif selection == 5 then
			love.event.quit()
		end
	end
end

function mainmenu.joystickpressed(joy, k)
	levelselection.enter()
end
