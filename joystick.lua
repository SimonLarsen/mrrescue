joystick = {}

local lg = love.graphics

function joystick.enter()
	state = STATE_JOYSTICK
	joystick.selection = 1
	joystick.waiting = false
end

function joystick.update(dt)
	
end

function joystick.draw()
	lg.push()
	lg.scale(config.scale)
	lg.setFont(font.bold)

	drawBox(40,54,176,95)

	lg.printf("SET JOYSTICK", 0, 39, WIDTH, "center")
	lg.print("DEVICE: ", 65, 66)
	local joyname = love.joystick.getName(config.joystick)
	if joyname then
		lg.print(string.upper(joyname:sub(1,10)), 125, 66)
	end
	for i=5,7 do
		lg.print(string.upper(keynames[i]), 65, 79+(i-5)*13)
		lg.print(string.upper(config.joykeys[keynames[i]]), 165, 66+(i-4)*13)
	end
	lg.print("DEFAULT", 65, 118)
	lg.print("BACK", 65, 131)

	lg.print(">", 52, 53+joystick.selection*13)

	lg.pop()
end

function joystick.keypressed(k, uni)
	if k == "down" then
		joystick.selection = wrap(joystick.selection + 1, 1, 6)
		playSound("blip")
	elseif k == "up" then
		joystick.selection = wrap(joystick.selection - 1, 1, 6)
		playSound("blip")
	
	elseif k == "return" then
		if joystick.selection == 6 then
			playSound("confirm")
			options.enter()
		end
	end
end
