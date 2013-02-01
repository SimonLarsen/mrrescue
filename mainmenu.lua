mainmenu = {}

lg = love.graphics

function mainmenu.enter()
	state = STATE_MAINMENU
end

function mainmenu.update(dt)

end

function mainmenu.draw()
	lg.push()
	lg.scale(SCALE)

	lg.drawq(img.splash, quad.splash, 0,0)
	lg.setFont(font.bold)
	lg.print("START GAME", 150, 104)
	lg.print("HIGHSCORES", 150, 117)
	lg.print("OPTIONS", 150, 130)
	lg.print("HISTORY", 150, 143)
	lg.print("EXIT", 150, 156)

	lg.pop()
end

function mainmenu.keypressed(k, uni)
	if k == "return" or k == " " then
		levelselection.enter()
	end
end

function mainmenu.joystickpressed(joy, k)
	levelselection.enter()
end
