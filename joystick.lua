joystick = {}

local lg = love.graphics

function joystick.enter()
	state = STATE_JOYSTICK
	joystick.selection = 1
	joystick.waiting = false
end

function joystick.update(dt)
	updateKeys()
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
		if joystick.waiting == true and joystick.selection == i-3 then
			lg.setColor(195,52,41)
		end
		lg.print(string.upper(keynames[i]), 65, 79+(i-5)*13)
		lg.print(string.upper(config.joykeys[keynames[i]]), 165, 66+(i-4)*13)
		lg.setColor(255,255,255)
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
		if joystick.selection == 1 then
			playSound("blip")
			nextJoystick()
		elseif joystick.selection >= 2 and joystick.selection <= 4 then -- Keys
			playSound("blip")
			joystick.waiting = true
		elseif joystick.selection == 5 then -- Default
			playSound("confirm")
			defaultJoyKeys()
		elseif joystick.selection == 6 then -- Back
			playSound("confirm")
			options.enter()
		end
	elseif k == "escape" then
		if joystick.waiting == true then
			joystick.waiting = false
			playSound("blip")
		else
			options.enter()
			playSound("confirm")
		end
	end
end

function joystick.joystickpressed(joy, k)
	if joystick.waiting == false then
		for a, key in pairs(config.joykeys) do
			if k == key then
				gamestates[state].action(a)
			end
		end
	else
		playSound("blip")
		config.joykeys[joykeynames[joystick.selection-1]] = k
		joystick.waiting = false
	end
end

function joystick.action(k)
	if k == "down" then
		joystick.selection = wrap(joystick.selection + 1, 1, 6)
		playSound("blip")
	elseif k == "up" then
		joystick.selection = wrap(joystick.selection - 1, 1, 6)
		playSound("blip")
	elseif k == "jump" then
		if joystick.selection == 1 then
			playSound("blip")
			nextJoystick()
		elseif joystick.selection >= 2 and joystick.selection <= 4 then -- Keys
			joystick.waiting = true
		elseif joystick.selection == 5 then -- DEFAULT
			playSound("confirm")
			defaultJoyKeys()
		elseif joystick.selection == 6 then -- BACK
			playSound("confirm")
			options.enter()
		end
	end
end
